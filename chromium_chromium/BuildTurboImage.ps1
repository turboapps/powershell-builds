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
$Vendor = "The Chromium Projects"
$AppDesc = "Chromium is an open-source browser project. This is a Stable Chromium build by Hibbiki."
$AppName = "Chromium Browser"
$VendorURL = "https://github.com/Hibbiki/chromium-win64/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Define the URL
$url = "https://github.com/Hibbiki/chromium-win64/releases/latest"

# Fetch the HTML content of the page
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$htmlContent = $response.Content

# Use regex to find version tags
$regex = 'tag\/([^"\/]+)"'
$matches = [regex]::Matches($htmlContent, $regex)

# Collect the first matched version tag
$versionTag = $matches[1].Groups[1].Value
$version = $versionTag -replace '^v', '' -replace '-r\d+$', ''

$InstalledVersion = RemoveTrailingZeros "$version"

# Get installer link for latest version
$DownloadLink = "https://github.com/Hibbiki/chromium-win64/releases/download/$versionTag/mini_installer.exe"

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Perform silent install into per-machine location
$ProcessExitCode = RunProcess $Installer "--install --silent --system-level" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Set the policy key to prevent the default browser banner
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Chromium /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f
# Set the policy key to prevent the Sign In prompt on first launch
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Chromium /v BrowserSignin /t REG_DWORD /d 0 /f

# Set the policy key to disable the chrome audio sandbox service
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Chromium /v AudioSandboxEnabled /t REG_DWORD /d 0 /f

# Delete the Installer folder to reduce the image size
Get-ChildItem -Path "C:\Program Files\Chromium\Application" -Directory -Recurse -Filter "Installer" | Remove-Item -Recurse -Force


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

