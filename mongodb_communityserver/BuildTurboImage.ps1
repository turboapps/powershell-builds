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
$Vendor = "MongoDB"
$AppDesc = "The Community version of our distributed database offers a flexible document data model along with support for ad-hoc queries, secondary indexing, and real-time aggregations."
$AppName = "MongoDB Community Server"
$VendorURL = "https://www.mongodb.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://www.mongodb.com/try/download/community' -UseBasicParsing

# Split the content into lines
$lines = $Page -split "`n"

# Use regex to match URLs that end with PBIDesktopSetupRS.exe
$regex = 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-[\d\.]+-signed\.msi'

# Find matches in the input string
$matches = [regex]::matches($lines, $regex)

$DownloadLink = $matches[0].Value

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]

# Get the version
$InstalledVersion = $InstallerName.Split("-")[3]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install MongoDB Community Server without the Windows Service, Compass and Router components
$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 MONGO_SERVICE_INSTALL=0 SHOULD_INSTALL_COMPASS=0 ADDLOCAL=ServerNoService,Server,ProductFeature,MiscellaneousTools /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Get the path to mongod.exe
$startupFilePath = Get-ChildItem -Path "C:\Program Files\MongoDB" -Recurse -Filter "mongod.exe" | Select-Object -ExpandProperty DirectoryName
$startupFileParent = (Get-Item $startupFilePath).Parent.FullName
# Create a Data directory for the database
New-Item -ItemType Directory -Force -Path "$startupFileParent\Data"


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
