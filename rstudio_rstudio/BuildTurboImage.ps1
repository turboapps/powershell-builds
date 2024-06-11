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
$Vendor = "Posit"
$AppDesc = "Open source and enterprise-ready professional software for R"
$AppName = "RStudio"
$VendorURL = "https://posit.co/download/rstudio-desktop/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion
    
##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$URL = 'https://posit.co/download/rstudio-desktop/'

# Get main download page for application.
$Page = curl $URL -UseBasicParsing

$DownloadLink = $Page.Links | Where-Object { $_.href -like '*windows/rstudio*' } | Select-Object -ExpandProperty href -First 1

$InstallerName = Split-Path -Path $DownloadLink -Leaf

$Installer = wget $DownloadLink -O $DownloadPath\$InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

New-Item -Path $env:APPDATA -Name "RStudio" -ItemType "directory" -Force # create an RStudio directory in APPDATA
New-Item -Path $env:LOCALAPPDATA -Name "RStudio" -ItemType "directory" -Force # create an RStudio directory in APPDATA

# Copy rstudio-prefs.json file to disable update checks
Copy-Item "$SupportFiles\rstudio-prefs.json" -Destination "$env:APPDATA\RStudio\"  -Force

# Copy crash-handler.conf to disable crash handler on first launch
Copy-Item "$SupportFiles\crash-handler.conf" -Destination "$env:APPDATA\RStudio\"  -Force

# Copy crash-handler-permission to disable crash handler on first launch
Copy-Item "$SupportFiles\crash-handler-permission" -Destination "$env:LOCALAPPDATA\RStudio\"  -Force

# Delete the Uninstall
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\RStudio\Uninstall.lnk" -Force
Remove-Item -Path "C:\Program Files\RStudio\Uninstall.exe" -Force

$InstalledVersion = ($InstallerName  -split '-')[1]

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

