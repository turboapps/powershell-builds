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
$Vendor = "turbo"
$AppDesc = "A tool to extract links from a URL using a headless browser."
$AppName = "headless-extractor"
$VendorURL = "https://turbo.net/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest HtmlAgilityPack."

# Get latest HtmlAgilityPack nuget package
$URL = "https://www.nuget.org/packages/HtmlAgilityPack/"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing

# Get download link for latest package
$DownloadLink = ($response.Links | Where-Object href -like '*/package/HtmlAgilityPack/*').href

# Name of the file to download to (will be a nupkg but needs to be named .zip so Powershell can extract the files)
$InstallerName = "HtmlAgilityPack.nupkg.zip"

# Download the installer
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract .zip
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\temp"

# Set this image version to whatever the latest Chrome version is on the Hub
$repo = "google/chrome"
$chromeVersion = GetCurrentHubVersion $repo
$InstalledVersion = $chromeVersion

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ExtractScriptPath = Join-Path -Path $scriptPath -ChildPath ".\SupportFiles\Extract.ps1"
$HtmlAgilityPackDllPath = "C:\temp\lib\Net45\HtmlAgilityPack.dll"

# Copy extractor script and HtmlAgilityPack.dll to folder.
# This will capture the files because it is a change.
echo F|. xcopy /i $ExtractScriptPath C:\extractor\Extract.ps1
echo F|. xcopy /i $HtmlAgilityPackDllPath C:\extractor\HtmlAgilityPack.dll

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Script and dll are not installed
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

