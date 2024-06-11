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
$Vendor = "Apple"
$AppDesc = "iTunes is the easiest way to enjoy your favorite music, movies, TV shows, and more on your PC."
$AppName = "iTunes 64-bit"
$VendorURL = "https://www.apple.com/itunes/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$DownloadLink = "https://www.apple.com/itunes/download/win64"
$InstallerName = "iTunes64Setup.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = Get-VersionFromExe $Installer

# Extract the installer
$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/Extract $DownloadPath" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install AppleMobileDeviceSupport64
$ProcessExitCode = RunProcess "msiexec.exe" "/I $DownloadPath\AppleMobileDeviceSupport64.msi ALLUSERS=1 REBOOT=ReallySuppress /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Install Bonjour
$ProcessExitCode = RunProcess "msiexec.exe" "/I $DownloadPath\Bonjour64.msi ALLUSERS=1 REBOOT=ReallySuppress /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Install iTunes without setting iTunes as the Default Media player (MEDIA_DEFAULTS=0)
$ProcessExitCode = RunProcess "msiexec.exe" "/I $DownloadPath\iTunes64.msi MEDIA_DEFAULTS=0 REBOOT=ReallySuppress ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 3010 $ProcessExitCode $False # Expected to exit with 3010 (reboot required) but will proceed on error in case exit code is 0.

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Disable iTunes Auto Update
&reg.exe ADD "HKLM\SOFTWARE\Apple Computer, Inc.\iTunes\Parental Controls\Default" /v AdminFlags /t REG_DWORD /d 257 /f /reg:64

# Suppress Apple iTunes Software License Agreement (EULA)
# Read the license.rtf line by line
$filePath = "C:\Program Files\iTunes\iTunes.Resources\en.lproj\License.rtf"
$fileContent = Get-Content -Path $filePath
# Loop through each line to find the pattern "EA####"
foreach ($line in $fileContent) {
    if ($line -match "EA(\d{4})") {
        $extractedNumber = $matches[1]
        break
    }
}
$RegValue = "EA" + $extractedNumber
&reg.exe ADD "HKLM\SOFTWARE\Apple Computer, Inc.\iTunes" /v SLA /t REG_SZ /d $RegValue /f /reg:64

# Remove the cached installer MSI files
Remove-Item -Path "C:\ProgramData\Apple" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Apple Computer" -Recurse -Force

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
