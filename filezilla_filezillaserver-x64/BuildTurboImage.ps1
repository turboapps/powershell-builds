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
## The turbo project and build are saved  to @DESKTOP@\Package\TurboCapture.
## Usage:
## Run this script from an elevated cmd prompt: Powershell -ExecutionPolicy Bypass -File <path>\scriptname.ps1
## Required:  You must have your Turbo Studio license in a "License.txt" file in an "Include" folder in the same folder as this script.
## Required:  You must have the "GlobalBuildScript.ps1" file in an "Include" folder in the same folder as this script.
## Required:  Any files used to customize the configuration should be a "Support Files" folder located in the same folder as this script.

$scriptPath = $PSScriptRoot  # The folder path the script was launched from
$GlobalScriptPath = Join-Path -Path $scriptPath -ChildPath "..\!include\GlobalBuildScript.ps1"  #Get the path to the GlobalBuildScript.ps1
. $GlobalScriptPath  # Include the script that contains global variables and functions
$SupportFiles = "$scriptPath\SupportFiles"  # The folder path contains files specific to this application build

# Check if the current script is running with elevated privileges
$elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If not running with elevated privileges, Log and Exit
if (-not $elevated) {
   WriteLog "This script must run elevated.  Please re-run as Administrator"
    # Exit the current script
    exit
}

###################################
## Define app specific variables ##
###################################
# These values will used to set the Metadata for the turbo image.

$HubOrg = (Split-Path $scriptPath -Leaf) -replace '_', '/' # Set the repo name based on the folder path of the script assuming the folder is vendor_appname
$Vendor = "FileZilla"
$AppDesc = "FileZilla is a free, open-source FTP server."
$AppName = "FileZilla Server 64-bit"
$VendorURL = "https://filezilla-project.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest ZIP archive."

# We need to use the windows curl.exe for this page as the powershell curl is blocked by the site
$url = "https://filezilla-project.org/download.php?type=server"
$page = EdgeGetContent -url $url -headlessMode "old"

# Define a regular expression pattern to match href links
$pattern = 'href\s*=\s*"(http[^"]*)"'
# Find all matches in the content
$matches = [regex]::Matches($page, $pattern)

# Extract the first link that contains "win64-setup" and display it
foreach ($match in $matches) {
    $DownloadLink = $match.Groups[1].Value
    if ($DownloadLink -like "*win64-setup*") {
        $DownloadLink = $DownloadLink -replace "amp;", ""
        break
    }
}

# Get the latest version tag.
$InstalledVersion = $DownloadLink.split("_")[2]

# Name of the downloaded installer file. Remove trailing signature text (?h=qqRKmF13eMCktg97-nJeQA&x=1707436613).
$InstallerName = ([System.IO.Path]::GetFileName($DownloadLink)).split("?")[0]
$Installer = Join-Path $DownloadPath $InstallerName

# Download installer
$userAgent = EdgeGetUserAgentString -headlessMode "old"
wget -Uri $DownloadLink -Headers @{"User-Agent"=$userAgent} -o $Installer

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Run installer:
# /S: silent install (not on wiki, but found a forum post at https://forum.filezilla-project.org/viewtopic.php?t=1233 describes this flag)
$ProcessExitCode = RunProcess $Installer "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Disable update check and welcome message.
(Get-Content("C:\ProgramData\filezilla-server\settings.xml")) -replace '(.*)<frequency>(.*)</frequency>(.*)','$1<frequency>0</frequency>$3' | Set-Content("C:\ProgramData\filezilla-server\settings.xml")
New-Item -Path "$env:LocalAppData\" -Name "filezilla-server" -ItemType Directory
Copy-Item "C:\ProgramData\filezilla-server\settings.xml" -Destination "$env:LocalAppData\filezilla-server"  -Force

# Remove uninstall shortcut.
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FileZilla Server\Uninstall FileZilla Server.lnk" -Recurse -Force

# Stop the FileZilla Server service.
Stop-Service filezilla-server

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."


#########################
## Stop Turbo Capture  ##
#########################

StopTurboCapture

######################
## Customize XAPPL  ##
######################

CustomizeTurboXappl "$SupportFiles\PostCaptureModifications.ps1"  # Helper script for XML changes to Xappl"

#########################
## Build Turbo Image   ##
#########################

BuildTurboSvmImage

########################
## Push Turbo Image   ##
########################

PushImage $InstalledVersion

