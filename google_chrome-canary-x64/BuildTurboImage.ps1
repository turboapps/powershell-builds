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
$Vendor = "Google"
$AppDesc = "Free web browser developed by Google, enhanced for performance and privacy from the Canary branch."
$AppName = "Chrome Canary 64-bit"
$VendorURL = "https://google.com/chrome"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Get installer link for latest version
## Download link taken from the following page: https://www.google.com/chrome/canary/?extra=canarychannel&platform=win64&standalone=1
$DownloadLink = "https://dl.google.com/tag/s/appguid%3D%7B4EA16AC7-FD5A-47C3-875B-DBF4A2008C20%7D%26iid%3D%7B1EE3173B-2ED4-11E2-361B-7A01EF107CD9%7D%26lang%3Den%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%2520Canary%26needsadmin%3Dfalse%26ap%3D-arch_x64-statsdef_1%26installdataindex%3Dempty/update2/installers/ChromeSetup.exe"

# Name of the downloaded installer file
$InstallerName = "ChromeSetup.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# /silent = unattended install
# /install = install application
$ProcessExitCode = RunProcess $DownloadPath\$InstallerName "/silent /install" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Copy initial_prefernces file - this file doesn't currently contain any changes to defaults but allows for future changes if required.
Copy-Item "$SupportFiles\initial_preferences" -Destination "$env:LOCALAPPDATA\Google\Chrome SxS\Application\"  -Force
# Copy Google folder to localappdata - this folder contains files to prevent the Google Welcome page on first launch.
Copy-Item -Path "$SupportFiles\Google" -Destination "$env:LOCALAPPDATA\" -Recurse -Force

# Create "Chrome Apps" folder in Start Menu - creating this folder will prevent google app shortcuts from getting created
Copy-Item -Path "$SupportFiles\Chrome Apps" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\" -Recurse -Force

# Kill updater.exe if running
taskkill.exe /f /im updater.exe /t

# Delete Google update folders
if (Test-Path "$env:LOCALAPPDATA\Google\Update") {
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Update\*" -Recurse -Force
}
if (Test-Path "$env:LOCALAPPDATA\Google\GoogleUpdater") {
    Remove-Item -Path "$env:LOCALAPPDATA\Google\GoogleUpdater\*" -Recurse -Force
}

$InstalledVersion = GetVersionFromRegistry "Google Chrome Canary"

# Delete installer files
if (Test-Path "$env:LOCALAPPDATA\Google\Chrome SxS\Application\$InstalledVersion\Installer") { 
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome SxS\Application\$InstalledVersion\Installer\*" -Recurse -Force 
}

# Set the policy key to prevent the default browser banner
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v PrivacySandboxPromptEnabled /t REG_DWORD /d 0 /f

# Set the policy key to disable the chrome audio sandbox service
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v AudioSandboxEnabled /t REG_DWORD /d 0 /f

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

