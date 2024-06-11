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
$Vendor = "Mozilla"
$AppDesc = "Mozillas popular open source browser enhanced for performance, privacy, and functionality."
$AppName = "Firefox 64-bit"
$VendorURL = "https://www.mozilla.org/en-US/firefox/new/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"

# Name of the downloaded installer file
$InstallerName = "FirefoxSetup.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the application
$ProcessExitCode = RunProcess $Installer "-ms /MaintenanceService=false /TaskbarShortcut=false /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Create ProgIDs for http and https
$ProcessExitCode = RunProcess "C:\Program Files\Mozilla Firefox\uninstall\helper.exe" "/SetAsDefaultAppUser" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $False # Proceed on install error
$ProcessExitCode = RunProcess "C:\Program Files\Mozilla Firefox\uninstall\helper.exe" "/SetAsDefaultAppGlobal" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $False # Proceed on install error

# Copy policies.json - to C:\Program Files\Mozilla Firefox\distribution
Copy-Item "$SupportFiles\distribution" -Destination "C:\Program Files\Mozilla Firefox\"  -Recurse -Force
# Copy mozilla.cfg - to C:\Program Files\Mozilla Firefox
Copy-Item "$SupportFiles\mozilla.cfg" -Destination "C:\Program Files\Mozilla Firefox\"  -Recurse -Force
# Copy local-settings.js - to C:\Program Files\Mozilla Firefox\defaults\pref
Copy-Item "$SupportFiles\defaults" -Destination "C:\Program Files\Mozilla Firefox\"  -Recurse -Force

# Delete all values under HKCU\SOFTWARE\Mozilla\Firefox\Launcher
&reg.exe delete "HKCU\SOFTWARE\Mozilla\Firefox\Launcher" /va /f
# Add back the Browser key.  This resolves an issue launching web pages.
&reg.exe add "HKCU\SOFTWARE\Mozilla\Firefox\Launcher" /t REG_QWORD /d 0 /v "C:\Program Files\Mozilla Firefox\firefox.exe|Browser" /f


################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."


$InstalledVersion = GetVersionFromRegistry "Firefox"


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

