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
$Vendor = "pgvector"
$AppDesc = "Open-source vector similarity search for Postgres."
$AppName = "pgvector"
$VendorURL = "https://github.com/pgvector/pgvector"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion
    
##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Download and extract the source files from GitHub
$DownloadLink = "https://github.com/pgvector/pgvector/archive/refs/heads/master.zip"
$InstallerName = "master.zip"
$Installer = wget $DownloadLink -UseBasicParsing -O $DownloadPath\$InstallerName
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath $DownloadPath

WriteLog "Pulling latest vsbuildtools and postgresql images from Hub."
WriteLog "> turbo pull microsoft/vsbuildtools,postgresql/postgresql"
. turbo pull microsoft/vsbuildtools,postgresql/postgresql

# Run the compiler on the source files from a turbo container using vsbuildtools and postgresql which are required for the compile action.
# The compile.bat script will create the pgvector extension files in the mounted native folder C:\pgvector-files\pgsql
WriteLog "> turbo try microsoft/vsbuildtools,postgresql/postgresql --mount=$DownloadPath --isolate=merge --startup-file=$SupportFiles\compile.bat"
. turbo try microsoft/vsbuildtools,postgresql/postgresql --mount=$DownloadPath --isolate=merge --startup-file="$SupportFiles\compile.bat"

# Get the version from the GitHub vector.control file
$Page = curl 'https://github.com/pgvector/pgvector/raw/master/vector.control' -UseBasicParsing
$Line =  $Page.Content -split "`n" | Where-Object { $_ -like '*default_version*' }
$LatestWebVersion = (($Line -split "=") -replace "'","")[1].Trim()
$InstalledVersion = RemoveTrailingZeros "$LatestWebVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Copying application files to be captured."

# Copy the compiled files to their final destination to be captured in the config
Copy-Item "$DownloadPath\pgsql" -Destination "C:\"  -Force -Recurse

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."


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

