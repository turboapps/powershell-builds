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
$Vendor = "Apache"
$AppDesc = "A free IDE for developing Java desktop, mobile, and web applications, including PHP and C/C++ plugin support."
$AppName = "Netbeans IDE"
$VendorURL = "https://netbeans.apache.org/front/main/index.html"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Download Netbeans
# Apache stopped publishing Windows installers after NetBeans 25. The Windows installer is now
# published by Friends of Apache NetBeans (FoAN) on GitHub. It is an Inno Setup installer that bundles its own Temurin JDK.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Release = Invoke-RestMethod -Uri "https://api.github.com/repos/Friends-of-Apache-NetBeans/netbeans-installers/releases/latest" -UseBasicParsing
$Asset = $Release.assets | Where-Object { $_.name -match '^Apache-NetBeans-[\d\.]+\.exe$' } | Select-Object -First 1
if (-not $Asset) {
    WriteLog "Could not find the Windows installer in the latest FoAN release ($($Release.tag_name)). Exiting."
    exit 1
}
$DownloadLink = $Asset.browser_download_url

# Name of the downloaded installer file
$InstallerName = $Asset.name

# Download the installer
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName


#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install Apache Netbeans silently for all users (Inno Setup installer with bundled JDK)
$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /ALLUSERS /SP-" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

$InstalledVersion = GetVersionFromRegistry "Netbeans"

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

