## This script will download the latest installer and create a Turbo SVM image in @DESKTOP@\Package\TurboCapture.
## The script is logged to @DESKTOP@\Package\Log.
## The turbo project and build are saved  to @DESKTOP@\Package\TurboCapture.
## Usage:
## Run this script from an elevated cmd prompt: Powershell -ExecutionPolicy Bypass -File <path>\scriptname.ps1
## Required:  You must have your Turbo Studio license in a "License.txt" file in an "Include" folder in the same folder as this script.
## Required:  You must have the "GlobalBuildScript.ps1" file in an "Include" folder in the same folder as this script.
## Required:  Any files used to customize the configuration should be a "Support Files" folder located in the same folder as this script.

$scriptPath = $PSScriptRoot  # The folder path the script was launched from
$GlobalScriptPath = Join-Path -Path $scriptPath -ChildPath "..\_INCLUDE\GlobalBuildScript.ps1"  #Get the path to the GlobalBuildScript.ps1
. $GlobalScriptPath  # Include the script that contains global variables and functions
$SupportFiles = "$scriptPath\SupportFiles"  # The folder path contains files specific to this application build


###################################
## Define app specific variables ##
###################################
# These values will used to set the Metadata for the turbo image.

$HubOrg = "paintdotnet/paintdotnet"  # Set this for each package
$Vendor = "dotPDN LLC"
$AppDesc = "Paint.NET is image and photo editing software for PCs that run Windows."
$AppName = "Paint.NET"
$VendorURL = "https://www.getpaint.net/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get main download page for application.
$Page = Invoke-WebRequest -Uri https://github.com/paintdotnet/release/releases/latest -UseBasicParsing

# Get the latest tag (used to build download link) and installed version (used to build download link and svm image meta).
$VersionTag = (($Page.Links | Where-Object {$_.href -like "*/releases/tag*"}).href).split("/")[-1]
$InstalledVersion = $VersionTag.Substring(1)

# Get installer link for latest version.
$DownloadLink = "https://github.com/paintdotnet/release/releases/download/" + $VersionTag + "/paint.net." + $InstalledVersion + ".winmsi.x64.zip"

# Folder the installer will be downloaded to
$DownloadPath = New-Item -Path $scriptPath -Name "Installer" -ItemType "directory" -Force # create an Installer directory on the desktop for the donwnload
# Name of the downloaded installer file
$InstallerName = [System.IO.Path]::GetFileName($DownloadLink)

$Installer = wget $DownloadLink -O $DownloadPath\$InstallerName

# Extract ZIP archive.
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath $DownloadPath

# Update InstallerName to extracted MSI.
$InstallerName = $installername.substring(0,$installername.length-3) + "msi"

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

