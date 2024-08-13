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
$Vendor = "OpenJS"
$AppDesc = "As an asynchronous event-driven JavaScript runtime, Node.js is designed to build scalable network applications."
$AppName = "Node.js LTS"
$VendorURL = "https://nodejs.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Use the vendor index to get the version
$nodejsIndex = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json

# Find the first version where the .lts property is not $false
$firstLTSVersion = $nodejsIndex | Where-Object { $_.lts -ne $false } | Select-Object -First 1
$LTSVersion = $firstLTSVersion.version

$DownloadLink = "https://nodejs.org/dist/$LTSVersion/node-$LTSVersion-x64.msi"
$InstallerName = "node-$LTSVersion-x64.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = Get-MsiProductVersion "$Installer"
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

WriteLog "Downloading the VCRedist installers."
# Donwload the VC++2015-2022 x64 Redistributable
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile "$DownloadPath\vc_redist.x64.exe"
# Donwload the VC++2015-2022 x86 Redistributable
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x86.exe -OutFile "$DownloadPath\vc_redist.x86.exe"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the VCRedist x64
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.x64.exe" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error
# Install the VCRedist x86
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.x86.exe" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Install the application
$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Remove unwanted shortcuts
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Node.js\Install Additional Tools for Node.js.lnk" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Node.js\Uninstall Node.js.lnk" -Recurse -Force

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
