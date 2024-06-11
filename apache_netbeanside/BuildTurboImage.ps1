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

# Download and Install the Ecplipse Temurin JDK
# We will use the Ecplipse Temurin JDK image from Turbo.net to download and install this app
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
$JDKInstallerName = $ReleaseInfo.binary.package.name
$JDKDownloadLink = "https://api.adoptium.net/v3/binary/latest/$latestMajorVersion/ga/$Platform/x64/$Type/hotspot/normal/eclipse"
$JDKInstaller = DownloadInstaller $JDKDownloadLink $DownloadPath $JDKInstallerName

# Download Netbeans
# Get download page for latest Netbeans version.
$URL = "https://dlcdn.apache.org/netbeans/netbeans-installers/"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$Page = $response.Links.Href[-1]
$URL = $URL + $Page
$Page2 = Invoke-WebRequest -Uri $URL -UseBasicParsing

# Get the URL for the latest 64bit exe
$LatestLink = $Page2.Links | Where-Object {$_.href -like "*windows-x64.exe"}
$DownloadLink = $URL + $LatestLink.href

# Name of the downloaded installer file
$InstallerName = $LatestLink.href

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

#Install the JDK
New-Item -Path "c:\Program Files" -Name "Eclipse Adoptium" -ItemType Directory
# Extract the zip file for the install
Expand-Archive -Path $DownloadPath\$JDKInstallerName -DestinationPath "C:\Program Files\Eclipse Adoptium"
$JDKDir = Get-ChildItem -Path "c:\Program Files\Eclipse Adoptium" -Directory | Where-Object { $_.Name -like 'jdk*' }
$JDKPath = $JDKDir.FullName

# Install Apache Netbeans silently using the Eclipse Temurin JDK
$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "--javahome `"$JDKPath`" --silent" $True
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

