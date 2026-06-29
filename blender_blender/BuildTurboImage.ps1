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
$Vendor = "Blender"
$AppDesc = "An open source 3D modeling, animation, and game creation tool."
$AppName = "Blender"
$VendorURL = "https://www.blender.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# --- Hop 1: main download page -> the /download/release/... link ---
$page = Invoke-WebRequest -Uri 'https://www.blender.org/download/'  -UseBasicParsing
$ReleaseLink = ([regex]::Matches($page.Content, 'https?://[^"'' ]*?\.msi/?') |
                ForEach-Object { $_.Value } | Select-Object -Unique |
                Where-Object { $_ -match 'windows-x64' } | Select-Object -First 1)

# --- Hop 2: the Thanks page -> the real mirror URLs ---
$thanks  = Invoke-WebRequest -Uri $ReleaseLink -UseBasicParsing
$mirrors = [regex]::Matches($thanks.Content, 'https?://[^"'' ]*?blender-[^"'' ]*?\.msi') |
           ForEach-Object { $_.Value } | Select-Object -Unique

# Prefer the official direct server, fall back to the first mirror
$DownloadLink = $mirrors | Where-Object { $_ -match 'download\.blender\.org' } | Select-Object -First 1
if (-not $DownloadLink) { $DownloadLink = $mirrors | Select-Object -First 1 }

Write-Output "Real download URL: $DownloadLink"

# --- Hop 3: download the actual MSI ---
$InstallerName = [regex]::Match($DownloadLink, '[^/]+\.msi').Value
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = [regex]::Match($InstallerName, 'blender-(\d+\.\d+(?:\.\d+)?)-windows').Groups[1].Value
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

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
