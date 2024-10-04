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
$Vendor = "The Document Foundation"
$AppDesc = "LibreOffice is a private, free and open source office suite – the successor project to OpenOffice."
$AppName = "Libre Office"
$VendorURL = "https://www.libreoffice.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion
    
##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://download.documentfoundation.org/libreoffice/stable/' -UseBasicParsing

$versionRegex = [regex]'\d+\.\d+\.\d+'
$versionMatches = $versionRegex.Matches($Page.Content)

# Get the last version from the matches
$InstalledVersion = $versionMatches[$versionMatches.Count - 1].Value

$InstallerName = 'LibreOffice_' + $InstalledVersion + '_Win_x86-64.msi'
$DownloadLink = "https://download.documentfoundation.org/libreoffice/stable/$InstalledVersion/win/x86_64/$InstallerName"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName


#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

#ADDLOCAL=ALL: This parameter instructs the MSI to install all LibreOffice features.
#CREATEDESKTOPLINK=0: When set to “0” no desktop icon is created, if you do want a desktop icon on your user’s computer change this to 1. 
#REGISTER_ALL_MSO_TYPES=1: Registers all Office types (Writer, Calc, Impress, etc.)
#REMOVE=gm_o_Onlineupdate: Adding this disables alerts from LibreOffice that your users would otherwise see asking them to update.
$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "ADDLOCAL=ALL CREATEDESKTOPLINK=0 REGISTER_ALL_MSO_TYPES=1 ISCHECKFORPRODUCTUPDATES=0 REMOVE=gm_o_Onlineupdate /qb REBOOT=ReallySuppress" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Copy the "LibreOffice" folder to the users AppData folder - the registrymodifications.xcu file in here will disable Auto Update
Copy-Item -Path "$SupportFiles\LibreOffice" -Destination "$env:APPDATA\" -Recurse -Force

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

