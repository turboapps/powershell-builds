## This script will download the latest installer and create a Turbo SVM image in @DESKTOP@\Package\TurboCapture.
## The script is logged to @DESKTOP@\Package\Log.
## The turbo project and build are saved  to @DESKTOP@\Package\TurboCapture.
## Usage:
## Run this script from an elevated cmd prompt: Powershell -ExecutionPolicy Bypass -File <path>\scriptname.ps1
## Required:  You must have your Turbo Studio license in a "License.txt" file in an "Include" folder in the same folder as this script.
## Required:  You must have the "GlobalBuildScript.ps1" file in an "Include" folder in the same folder as this script.
## Required:  Any files used to customize the configuration should be a "Support Files" folder located in the same folder as this script.

. "$PSScriptRoot\Include\GlobalBuildScript.ps1"  # Include the script that contains global variables and functions
$scriptPath = $PSScriptRoot  # The folder path the script was launched from
$SupportFiles = "$scriptPath\SupportFiles"  # The folder path contains files specific to this application build


###################################
## Define app specific variables ##
###################################
# These values will used to set the Metadata for the turbo image.

$HubOrg = "cisco/webex-x64"  # Set this for each package
$Vendor = "Cisco Systems"
$AppDesc = "Webex is your one place to call, message, meet."
$AppName = "Webex (64-bit)"
$VendorURL = "https://www.webex.com/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://binaries.webex.com/WebexTeamsDesktop-Windows-Gold/Webex_en.msi"

# Folder the installer will be downloaded to
$DownloadPath = New-Item -Path $scriptPath -Name "Installer" -ItemType "directory" -Force # create an Installer directory on the desktop for the donwnload
# Name of the downloaded installer file
$InstallerName = "Webex_en.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 AUTOUPGRADEENABLED=0 ENABLEVDI=2 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

$ProcessExitCode = RunProcess "C:\Program Files\Cisco Spark\WebView2Runtime\MicrosoftEdgeWebview2Setup.exe" "/silent /install" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."


# Get the installed version from the registry
foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
    $name = (Get-ItemProperty $subkey.PSPath).DisplayName
    if ($name -eq "Webex") {
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

