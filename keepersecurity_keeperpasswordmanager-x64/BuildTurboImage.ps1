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
$Vendor = "Keeper Security"
$AppDesc = "Keeper is the leading cybersecurity platform for preventing password-related data breaches and cyberthreats."
$AppName = "Keeper Password Manager 64-bit"
$VendorURL = "https://www.keepersecurity.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################

WriteLog "Downloading the VCRedist installer."
# Donwload the VC++2015-2022 x64 Redistributable
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile "$DownloadPath\vc_redist.x64.exe"

WriteLog "Downloading the latest MSIX installer."
# Get installer link for latest version
$DownloadLink = "https://www.keepersecurity.com/desktop_electron/packages/KeeperPasswordManager.msixbundle"

# Name of the downloaded installer file
$InstallerName = "KeeperPasswordManager.msixbundle"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

# Replace the SnapshotSettings_21.xml file to include C:\Program Files\WindowsApps folder in the capture
New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA\Turbo.net
Copy-Item -Path "$SupportFiles\Turbo Studio 24" -Destination "$env:LOCALAPPDATA\Turbo.net" -Recurse -Force

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the VCRedist
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.x64.exe" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Install the MSIX Keeper application
$ProcessExitCode = RunProcess "powershell.exe" "Add-AppxPackage -Path $Installer" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error



################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Look for the keeperpasswordmanager.exe
$exePath = Get-ChildItem -Path "C:\Program Files\WindowsApps" -Filter "keeperpasswordmanager.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
# Create Start Menu shortcut
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Keeper Password Manager.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.Save()

WriteLog "Start menu shortcut created: $shortcutPath"

$InstalledVersion = Get-VersionFromExe $exePath


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

