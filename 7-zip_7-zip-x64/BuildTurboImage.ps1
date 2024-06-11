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
$Vendor = "7-Zip"
$AppDesc = "Open source file archiver and compression tool."
$AppName = "7-Zip 64-bit"
$VendorURL = "https://7-zip.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

$Page = curl 'https://www.7-zip.org/download.html' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*-x64.msi"})[0].href
$DownloadLink = "https://www.7-zip.org/" + $LatestInstaller

# Name of the downloaded installer file
$InstallerName = $LatestInstaller.Split("/")[1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Associate file types with 7zFM.exe
  &cmd.exe /C assoc .7z=7-Zip.7z
  &cmd.exe /C --% ftype 7-Zip.7z="C:\Program Files\7-Zip\7zFM.exe" "%1"
  &cmd.exe /C assoc .zip=7-Zip.zip
  &cmd.exe /C --% ftype 7-Zip.zip="C:\Program Files\7-Zip\7zFM.exe" "%1"
  &cmd.exe /C assoc .bz2=7-Zip.bz2
  &cmd.exe /C --% ftype 7-Zip.bz2="C:\Program Files\7-Zip\7zFM.exe" "%1"
  &cmd.exe /C assoc .gz=7-Zip.gz
  &cmd.exe /C --% ftype 7-Zip.gz="C:\Program Files\7-Zip\7zFM.exe" "%1"
  &cmd.exe /C assoc .tar=7-Zip.tar
  &cmd.exe /C --% ftype 7-Zip.tar="C:\Program Files\7-Zip\7zFM.exe" "%1"
  &cmd.exe /C assoc .tgz=7-Zip.tgz
  &cmd.exe /C --% ftype 7-Zip.tgz="C:\Program Files\7-Zip\7zFM.exe" "%1"
  
$InstalledVersion = GetVersionFromRegistry "7-zip"

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
