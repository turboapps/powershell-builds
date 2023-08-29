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

$HubOrg = "7-zip/7-zip-x64"  # Set this for each package
$Vendor = "7-Zip"
$AppDesc = "Open source file archiver and compression tool."
$AppName = "7-Zip (64-bit)"
$VendorURL = "https://7-zip.org/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

$Page = Invoke-WebRequest -Uri 'https://www.7-zip.org/download.html' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*-x64.msi"})[0].href
$DownloadLink = "https://www.7-zip.org/" + $LatestInstaller

# Folder the installer will be downloaded to
$DownloadPath = New-Item -Path $scriptPath -Name "Installer" -ItemType "directory" -Force # create an Installer directory on the desktop for the donwnload

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
  &cmd.exe /C --% ftype 7-Zip.7z="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  &cmd.exe /C assoc .zip=7-Zip.zip
  &cmd.exe /C --% ftype 7-Zip.zip="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  &cmd.exe /C assoc .bz2=7-Zip.bz2
  &cmd.exe /C --% ftype 7-Zip.bz2="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  &cmd.exe /C assoc .gz=7-Zip.gz
  &cmd.exe /C --% ftype 7-Zip.gz="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  &cmd.exe /C assoc .tar=7-Zip.tar
  &cmd.exe /C --% ftype 7-Zip.tar="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  &cmd.exe /C assoc .tgz=7-Zip.tgz
  &cmd.exe /C --% ftype 7-Zip.tgz="C:\Program Files\7-Zip\7zFM.exe" "%%1"
  
# Get the installed version from the registry
foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
    $name = (Get-ItemProperty $subkey.PSPath).DisplayName
    if ($name -match "7-Zip") {
        $InstalledVersion = (Get-ItemProperty $subkey.PSPath).DisplayVersion
    }
}

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

