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
$Vendor = "ggerganov"
$AppDesc = "A port of OpenAI's Whisper model in C/C++."
$AppName = "whisper.cpp"
$VendorURL = "https://github.com/ggerganov/whisper.cpp"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest .ZIP."

# Get latest version tag from repo
$URL = "https://api.github.com/repos/ggerganov/whisper.cpp/releases/latest"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = (ConvertFrom-Json $response.Content).tag_name
$latest -match "v(\d.\d.\d)"

$InstalledVersion = $matches[1]

# Get download link for latest version
$DownloadLink = "https://github.com/ggerganov/whisper.cpp/archive/refs/tags/v$InstalledVersion.zip"

# Name of the .zip file
$InstallerName = "whisper.zip"

# Download the installer
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract .zip
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\"
$SourceDir = "C:\whisper.cpp-source"
Rename-Item -Path "C:\whisper.cpp-$InstalledVersion" -NewName $SourceDir

WriteLog "Pulling latest vsbuildtools image from Hub."
WriteLog "> turbo pull microsoft/vsbuildtools"
. turbo pull microsoft/vsbuildtools

# Run the compiler on the source files from a turbo container using vsbuildtools which is required for the compile action.
# The compile.bat script will compile in the folder C:\whisper.cpp-source\build
WriteLog "> turbo try microsoft/vsbuildtools,postgresql/postgresql --mount=$DownloadPath --isolate=merge --startup-file=$SupportFiles\compile.bat"
. turbo try microsoft/vsbuildtools --isolate=merge --startup-file="$SupportFiles\compile.bat"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Copy whisper.cpp files to folder.
# This will capture the files because it is a change.
echo F|. xcopy /i $SourceDir\build\bin\Release\main.exe C:\whisper.cpp\main.exe
echo F|. xcopy /i $SourceDir\build\bin\Release\whisper.dll C:\whisper.cpp\whisper.dll

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# whisper.cpp is built from source, it is not installed
# $InstalledVersion = GetVersionFromRegistry ""

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

