param(
    [Parameter(Mandatory=$false)]
    [string]$Import,  # If -Import is $true the image will be imported after built
    [Parameter(Mandatory=$false)]
    [string]$PushURL,    # If -Push is a URL, the image will be pushed to the Turbo Server
    [Parameter(Mandatory=$false)]
    [string]$ApiKey   # If -ApiKey is provided it will be used for the image push
)

## This script will download the latest installer and create a Turbo SVM image in @DESKTOP@\Package\TurboCapture.
## The script is logged to @DESKTOP@\Package\Log.
## The turbo project and build are saved to @DESKTOP@\Package\TurboCapture.
## Usage:
## Run this script from an elevated cmd prompt: Powershell -ExecutionPolicy Bypass -File <path>\scriptname.ps1
## Required:  You must have your Turbo Studio license in a "License.txt" file in an "Include" folder in the same folder as this script.
## Required:  You must have the "GlobalBuildScript.ps1" file in an "Include" folder in the same folder as this script.
## Required:  Any files used to customize the configuration should be a "Support Files" folder located in the same folder as this script.

$scriptPath = $PSScriptRoot
$GlobalScriptPath = Join-Path -Path $scriptPath -ChildPath "..\!include\GlobalBuildScript.ps1"
. $GlobalScriptPath
$SupportFiles = "$scriptPath\SupportFiles"

$elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $elevated) {
    WriteLog "This script must run elevated. Please re-run as Administrator"
    exit
}

###################################
## Define app specific variables ##
###################################
$HubOrg = (Split-Path $scriptPath -Leaf) -replace '_', '/'
$Vendor = "KLayout"
$AppDesc = "Open-source layout editor for chip design and mask layout."
$AppName = "KLayout"
$VendorURL = "https://www.klayout.de/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Discovering the latest KLayout Windows 32-bit installer."

$downloadPage = "https://www.klayout.de/build.html"
$downloadHtml = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
$downloadUrl = $null

$matches = [regex]::Matches($downloadHtml.Content, 'https://[^"\s<>]+')
foreach ($match in $matches) {
    $candidate = $match.Value
    if ($candidate -match 'klayout' -and $candidate -match '\.exe$' -and $candidate -match '(?i)(win32|32-bit|32bit|x86|i386|i686)') {
        $downloadUrl = $candidate
        break
    }
}

if (-not $downloadUrl) {
    WriteLog "No suitable KLayout Windows 32-bit installer URL was found on the download page."
    throw "Unable to determine the current KLayout Windows 32-bit installer URL."
}

$InstallerName = [System.IO.Path]::GetFileName($downloadUrl)
$Installer = DownloadInstaller $downloadUrl $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################
StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."
$ProcessExitCode = RunProcess $Installer "/S /D=C:\Program Files (x86)\KLayout" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."
$InstalledVersion = GetVersionFromRegistry "KLayout"

# Copy the initial klayoutrc preferences file to disable tips dialog on startup.
New-Item -Path "$env:USERPROFILE\KLayout" -ItemType Directory -Force
Copy-Item "$SupportFiles\@PROFILE@\KLayout\klayoutrc" -Destination "$env:USERPROFILE\KLayout\klayoutrc"  -Force

#########################
## Stop Turbo Capture ##
#########################
StopTurboCapture

######################
## Customize XAPPL  ##
######################
CustomizeTurboXappl "$SupportFiles\PostCaptureModifications.ps1"

#########################
## Build Turbo Image   ##
#########################
BuildTurboSvmImage

########################
## Push Turbo Image   ##
########################
PushImage $InstalledVersion
