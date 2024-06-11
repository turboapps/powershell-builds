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
$Vendor = "Eclipse Adoptium"
$AppDesc = "Eclipse Temurin is the open source Java SE build based upon OpenJDK"
$AppName = "Temurin JDK"
$VendorURL = "https://adoptium.net/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Get major version of the latest release
$url = "https://api.adoptium.net/v3/info/available_releases"
$response = curl -Uri $url -UseBasicParsing
$jsonData = $response.Content | ConvertFrom-Json
$latestMajorVersion = $jsonData.available_releases[-1]

# Use the vendor API to get the latest release given the major version
$Platform = 'windows'
$Type = 'jdk'
$ReleaseInfo = Invoke-WebRequest -Uri "https://api.adoptium.net/v3/assets/latest/$latestMajorVersion/hotspot?architecture=x64&image_type=$Type&os=$Platform&vendor=eclipse" -UseBasicParsing | ConvertFrom-Json

# Download the zip
$InstallerName = $ReleaseInfo.binary.package.name
$DownloadLink = "https://api.adoptium.net/v3/binary/latest/$latestMajorVersion/ga/$Platform/x64/$Type/hotspot/normal/eclipse"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = $InstallerName.Split("_")[-2]

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

New-Item -Path "c:\Program Files" -Name "Eclipse Adoptium" -ItemType Directory
# Extract the zip file for the install
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\Program Files\Eclipse Adoptium"

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Register .jar files with javaw.exe
$InstallDir = Get-ChildItem -Path "c:\Program Files\Eclipse Adoptium" -Directory | Where-Object { $_.Name -like 'jdk*' }

$regKey = "HKLM:\SOFTWARE\Classes\.jar"
if (-not (Test-Path $regKey)) {New-Item -Path $regKey -Force | Out-Null}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\.jar" -Name '(Default)' -Value "Eclipse Adoptium.jarfile"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\.jar" -Name 'Content Type' -Value "application/java-archive"

$regKey = "HKLM:\SOFTWARE\Classes\Eclipse Adoptium.jarfile\shell\open\command"
if (-not (Test-Path $regKey)) {New-Item -Path $regKey -Force | Out-Null}
Set-ItemProperty -Path $regKey -Name '(Default)' -Value "`"C:\Program Files\Eclipse Adoptium\$($InstallDir)\bin\javaw.exe`" -jar `"%1`" %*"



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

