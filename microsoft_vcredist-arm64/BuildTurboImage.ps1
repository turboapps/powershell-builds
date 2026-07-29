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
$Vendor = "Microsoft"
$AppDesc = "Many applications built using Microsoft C and C++ tools require these libraries."
$AppName = "Microsoft Visual C++ Redistributable ARM64"
$VendorURL = "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Get installer for latest version
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.arm64.exe -OutFile "$DownloadPath\vc_redist.arm64.exe"

$InstalledVersion = Get-VersionFromExe "$DownloadPath\vc_redist.arm64.exe"
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Use /norestart - on WoA a silent vc_redist install performs the required restart and reboots the capture VM
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.arm64.exe" "/install /quiet /norestart" $True
# 3010 = ERROR_SUCCESS_REBOOT_REQUIRED: the install succeeded and only a reboot is
# pending - the ARM64 CRT consistently returns this on a clean image, so treat as success
if ($ProcessExitCode -eq 3010) { $ProcessExitCode = 0 }
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Get the year version from the Unintall registry key (eg Microsoft Visual C++ 2022 ARM64 Minimum Runtime - 14.38.33135)
# The arm64 runtime registers in the native hive, not WOW6432Node - check both
$UninstallPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
$UninstallNames = $UninstallPaths | Where-Object { Test-Path $_ } | Get-ChildItem | ForEach-Object { (Get-ItemProperty $_.PSPath).DisplayName }

$RegistryVersion = $UninstallNames | Where-Object { $_ -match "Minimum Runtime" } | Select-Object -Last 1
# The arm64 redist registers only the bundle entry (eg Microsoft Visual C++ 2015-2022 Redistributable (Arm64) - 14.44.35211),
# not the per-MSI "Minimum Runtime" entries the x64 recipe matches on - fall back to the bundle name
if (-not $RegistryVersion) {
    $RegistryVersion = $UninstallNames | Where-Object { $_ -match "Visual C\+\+.*Redistributable" } | Select-Object -Last 1
}

# Parse out the year from the registry key - take the last year so "2015-2022" yields 2022.
# Lookarounds require exactly 4 digits, so version numbers like 35211 never match.
$extractedVersion = ([regex]::Matches("$RegistryVersion", '(?<!\d)\d{4}(?!\d)') | Select-Object -Last 1).Value


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
#Publish a second time using the Year version (eg 2022)
# Guarded - a failed parse must skip this push, not publish an empty tag
if ($extractedVersion -match '^\d{4}$') {
    PushImage $extractedVersion
}
else {
    WriteLog "Could not determine year version from uninstall entries - skipping the year-tagged push."
}

