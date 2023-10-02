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

$HubOrg = "microsoft/powerbi-x32"  # Set this for each package
$Vendor = "Microsoft"
$AppDesc = "Power BI Desktop is a business analytics application that provides interactive visualizations, and self-service business intelligence capabilities."
$AppName = "PowerBI Desktop (32-bit)"
$VendorURL = "https://powerbi.microsoft.com/en-us/desktop/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup.exe"

# Name of the downloaded installer file
$InstallerName = "PBIDesktopSetup.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "-q ACCEPT_EULA=1 DISABLE_UPDATE_NOTIFICATION=1 ENABLECXP=0" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Register .net registration-free COM objects 
&reg.exe import "$SupportFiles\RegCOMObjects.reg"

# This prevents a “Get the most out of PowerBI” dialog on second launch of PowerBI
&reg.exe ADD "HKCU\SOFTWARE\Microsoft\Microsoft Power BI Desktop" /v ShowLeadGenDialog /t REG_DWORD /d 0 /f

# Add system env var to launch msedgewebview2 with --no-sandbox parameter ** ONLY REQUIRED WITH TURBO VM LOWER THAN 23.4.3 **
# &reg.exe ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS /t REG_SZ /d --no-sandbox /f

# Get the installed version from the registry
foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")) {
    $name = (Get-ItemProperty $subkey.PSPath).DisplayName
    if ($name -eq "Microsoft Power BI Desktop") {
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

