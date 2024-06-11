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
$Vendor = "Turbo"
$AppDesc = "OpenSearch configuration layer for Turbo Server."
$AppName = "OpenSearch Config for Turbo Server"
$VendorURL = "https://turbo.net/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################

WriteLog "Pulling latest opensearch image from Hub."
WriteLog "> turbo pull opensearch/opensearch"
. turbo pull opensearch/opensearch

# Copy config file out of image using a temporary container (turbo try).
# Mount the package folder to write the file out to the native filesystem from the container.
WriteLog "Copy config file out of image using temporary container."
WriteLog "> turbo try opensearch/opensearch --mount=$DownloadPath --startup-file=cmd -- /c xcopy c:\opensearch\config\opensearch.yml $DownloadPath"
. turbo try opensearch/opensearch --mount=$DownloadPath --startup-file=cmd -- /c xcopy c:\opensearch\config\opensearch.yml $DownloadPath

WriteLog "Customizing config for Turbo Server use case."
$ConfigFile = Join-Path $DownloadPath "opensearch.yml"
Add-Content -Path $ConfigFile -Value ""
Add-Content -Path $ConfigFile -Value "# Allow making queries to the opensearch server anonymously without using SSL certificates"
Add-Content -Path $ConfigFile -Value "plugins.security.disabled: true"
Add-Content -Path $ConfigFile -Value ""
Add-Content -Path $ConfigFile -Value "# Set path to restore backups from"
Add-Content -Path $ConfigFile -Value "path.repo: [""C:/opensearch/snapshots""]"

# Get the version tag from the image that was pulled.
$TurboImages = (ConvertFrom-Json (. turbo images --format=json)).result.images
$VersionTag = ($TurboImages | Where-Object {$_.namespace -eq "opensearch"} | Where-Object {$_.name -eq "opensearch"} | Sort-Object -Property tag)[0].tag
# VersionTag is the same as InstalledVersion for this application.
$InstalledVersion = $VersionTag



#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Copy config file to appropriate path.
. mkdir C:\opensearch\config
Copy-Item $ConfigFile -Destination c:\opensearch\Config

# Create folder for backups
# Will set to merge isolation in PostSnapshotModifications
. mkdir c:\opensearch\snapshots

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

