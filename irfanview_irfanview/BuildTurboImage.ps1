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
$Vendor = "Irfanview"
$AppDesc = "A fast and compact image viewer and converter."
$AppName = "Irfanview"
$VendorURL = "https://www.irfanview.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Parse download page for latest version.
$Page = curl 'https://www.irfanview.com/' -UseBasicParsing
## match operator populates the $matches variable.
$Page -match "Version (.*)</span>"
$LatestWebVersion = $matches[1]

# Parse download page for installer name.
$Page -match "https://.*(iview.*_setup.exe)"
$InstallerName = $matches[1]

# Parse download page for download link. 
# Main page lists FossHub, which does not allow direct download links. Build the Techspot download link instead.
# $Page -match "(https://.*iview.*_setup.exe)"
# $DownloadLink = $matches[1]
$DownloadLink = "https://files02.tchspt.com/down/$InstallerName"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = $LatestWebVersion
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Perform silent MSI installation
## silent = unattended install
## desktop = create desktop shortcut
## thumbs = create desktop shortcut for thumbnails
## group = create group in Start Menu
## allusers = install in program folder for all users
## assoc = set file associations
## https://www.irfanview.com/faq.htm
$ProcessExitCode = RunProcess $Installer "/silent /desktop=1 /thumbs=1 /group=1 /allusers=1 /assoc=1" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Capture first launch to isolate user appdata folers
RunProcess "C:\Program Files (x86)\IrfanView\i_view32.exe" $Null $False
Start-Sleep -Seconds 60
# Stop application
RunProcess "taskkill.exe" "/im i_view32.exe" $True

Start-Sleep -Seconds 90

#########################
## Stop Turbo Capture  ##
#########################

StopTurboCapture

######################
## Customize XAPPL  ##
######################

CustomizeTurboXappl "$SupportFiles\PostCaptureModifications.ps1"  # Helper script for XML changes to Xappl"

WriteLog "Find and replace operations completed successfully."

#########################
## Build Turbo Image   ##
#########################

BuildTurboSvmImage

########################
## Push Turbo Image   ##
########################

PushImage $InstalledVersion
