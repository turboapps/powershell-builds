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
$Vendor = "OpenSearch"
$AppDesc = "OpenSearch is a distributed search and analytics engine."
$AppName = "OpenSearch"
$VendorURL = "https://opensearch.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest ZIP archive."

# Get main download page for application.
$Page = curl https://opensearch.org/downloads.html -UseBasicParsing

# Get the latest version tag and installed version (used to build download link and svm image meta).
$VersionTag = (($Page.Links | Where-Object {$_.href -like "https://artifacts.opensearch.org/releases/bundle/opensearch/*windows-x64.zip"}).href).split("-")[1]
# VersionTag is the same as InstalledVersion for this application.
$InstalledVersion = $VersionTag

# Get installer link for latest version.
$DownloadLink = (($Page.Links | Where-Object {$_.href -like "https://artifacts.opensearch.org/releases/bundle/opensearch/*windows-x64.zip"}).href)

# Name of the downloaded installer file
$InstallerName = [System.IO.Path]::GetFileName($DownloadLink)

$Installer = wget $DownloadLink -O $DownloadPath\$InstallerName

# Extract ZIP archive.
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Rename verseioned opensearch-[vers] to opensearch folder.
# This will also capture the files because it is a change.
# Move-Item is not captured by Studio.
# Move-Item (Get-Item "C:\opensearch-*") C:\opensearch\

# Copy the files instead of using Move-Item.
. xcopy /s/e/h (Get-Item "C:\opensearch-*").FullName C:\opensearch\

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# OpenSearch is not an installed application, but simply an extracted ZIP.
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

