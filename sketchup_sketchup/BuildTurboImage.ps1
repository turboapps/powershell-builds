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
$Vendor = "Trimble"
$AppDesc = "The easiest way to draw in 3D"
$AppName = "SketchUp"
$VendorURL = "https://sketchup.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get main download page for application.
$Page = curl 'https://www.sketchup.com/en/download/all' -UseBasicParsing

# Get download page for latest version.
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*.exe*"}).href[0]

# Name of the downloaded installer file
$InstallerName = $DownloadLink.split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Get the latest version tag.
$InstalledVersion = Get-VersionFromExe "$Installer"
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

$LatestMajorVer = ($InstalledVersion -split '\.')[0]

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/silent" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Remove Layout and Style Builder shortcuts from the desktop
$desktopPath = "C:\users\public\desktop"
$shortcutFiles = Get-ChildItem -Path $desktopPath -File | Where-Object { $_.Name -like "layout*.lnk" -or $_.Name -like "style builder*.lnk" }
foreach ($file in $shortcutFiles) {
    Remove-Item $file.FullName -Force
}

# Copy preference json files to prevent the EULA and disable auto-updates in SketchUp and LayOut
$SketchupDir = Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "SketchUp.exe" -ErrorAction SilentlyContinue
$installDir = $SketchupDir.Directory.FullName
$SketchupDir = $installDir.Split("\")[-1]  # Get the major version folder for Sketchup

# Pre-create sketchup and layout appdata and localappdata folders
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\SketchUp" -Force
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\SketchUp\$SketchupDir" -Force
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\SketchUp\$SketchupDir\SketchUp" -Force
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\SketchUp\$SketchupDir\LayOut" -Force
New-Item -ItemType Directory -Path "$env:APPDATA\SketchUp" -Force
New-Item -ItemType Directory -Path "$env:APPDATA\SketchUp\$SketchupDir" -Force
New-Item -ItemType Directory -Path "$env:APPDATA\SketchUp\$SketchupDir\SketchUp" -Force
# Copy json preferences files
Copy-Item -Path "$SupportFiles\PrivatePreferences.json" -Destination "$env:LOCALAPPDATA\SketchUp\$SketchupDir\SketchUp\" -Force
Copy-Item -Path "$SupportFiles\layout.private.json" -Destination "$env:LOCALAPPDATA\SketchUp\$SketchupDir\LayOut\" -Force
Copy-Item -Path "$SupportFiles\SharedPreferences.json" -Destination "$env:APPDATA\SketchUp\$SketchupDir\SketchUp\" -Force



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

PushImage $LatestMajorVer

