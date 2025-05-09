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
$AppDesc = "LLM inference in C/C++."
$AppName = "llama.cpp"
$VendorURL = "https://github.com/ggerganov/llama.cpp"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest .ZIPs."

# Get latest version tag from repo
$URL = "https://api.github.com/repos/ggerganov/llama.cpp/releases/latest"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = (ConvertFrom-Json $response.Content).tag_name
$latest -match "b(\d+)"

$InstalledVersion = $matches[1] + ".0"

$BuildFiles = "C:\build_files"
$Builds = "cpu","cuda12.4"
foreach ($Build in $Builds) {
    # Get download link for latest version for build
    $DownloadLink = "https://github.com/ggerganov/llama.cpp/releases/download/$latest/llama-$latest-bin-win-$Build-x64.zip"

    # Name of the .zip file
    $InstallerName = [System.IO.Path]::GetFileName($DownloadLink)

    # Download the installer
    $DownloadLink
    $Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

    # Extract .zip
    Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath $BuildFiles\$Build
}

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Copy all files for all llama.cpp builds to folders.
# This will capture the files because it is a change.
foreach ($Build in $Builds) {
    $FinalBuildPath = "C:\llama-$Build"
    mkdir "C:\llama-$build"
    echo F|. xcopy /i $BuildFiles\$Build\llama-cli.exe $FinalBuildPath\llama-cli.exe
    echo F|. xcopy /i $BuildFiles\$Build\llama-server.exe $FinalBuildPath\llama-server.exe
    echo F|. xcopy /i $BuildFiles\$Build\llama-llava-cli.exe $FinalBuildPath\llama-llava-cli.exe

    # Copy all .dll files from the source folder to the destination.
    Get-ChildItem -Path "$BuildFiles\$Build" -Filter "*.dll" | ForEach-Object {
        echo F|. xcopy /i $_.FullName "$FinalBuildPath\$($_.Name)"
    }
}

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# llama.cpp is not installed
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

