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
$Vendor = "Adobe"
$AppDesc = "View, print, search, sign, verify, and collaborate on PDF documents."
$AppName = "Acrobat Reader 64-bit"
$VendorURL = "https://adobe.com"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get latest version for Acrobat Reader from their SCUP page.
## Download SCUP cab.
Wget https://armmf.adobe.com/arm-manifests/win/SCUP/ReaderCatalog-DC.cab -OutFile "$DownloadPath\ReaderCatalog.cab"
## Expand cab to XML.
Expand "$DownloadPath\ReaderCatalog.cab" -F:* "$DownloadPath\ReaderCatalog.xml"

## Parse XML for latest version
[XML]$ReaderCatalog = Get-Content("$DownloadPath\ReaderCatalog.xml")
$Versions = $ReaderCatalog.SystemsManagementCatalog.SoftwareDistributionPackage.InstallableItem.ApplicabilityRules.MetaData.MsiPatchMetaData.MsiPatch.TargetProduct.UpdatedVersion | Sort-Object -Descending
$Version = $Versions[0] -Replace ('\.','')

## Create download link for Reader
$DownloadLink = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/" + $Version + "/AcroRdrDCx64" + $Version + "_en_US.exe"

# Name of the downloaded installer file
$InstallerName = "AcroRdrDCx64.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# DISABLE_NOTIFICATIONS=1 prevents the ReaderNotificationClient AppX app from getting installed and prevents msiexec from prompting for UAC after the Adobe Sign In
$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/sAll /rs /l /msi /qb-! /norestart ALLUSERS=1 EULA_ACCEPT=YES SUPPRESS_APP_LAUNCH=YES DISABLE_NOTIFICATIONS=1" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Set Adobe preferences https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunchWin10 /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunch /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 10 /v iFTEVersion /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 0 /v iLastCardShown /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /t REG_DWORD /d 0 /v bShowMsgAtLaunch /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 1 /v bToggleFTE /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 1 /v bToggleToDoList /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bWhatsNewExp /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bProtectedMode /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bUpdater /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bShowUpgradePrompt /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 1 /v bAcroSuppressUpsell /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bReaderRetentionExperiment /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bUsageMeasurement /f

# Delete Adobe ARM service
&sc.exe stop adobearmservice
&sc.exe delete adobearmservice
# Delete Adobe update scheduled task
&schtasks /delete /tn "adobe acrobat update task" /f
# Cleanup installer files
&cmd.exe /c rmdir /S /Q "C:\program files\common files\adobe\acrobat\setup"

# Rename the 'Adobe Crash Processor.exe' as it causes the turbo container to take a long time to stop after closing the app
# & cmd.exe /c rename "C:\Program Files\Adobe\Acrobat DC\Acrobat\Adobe Crash Processor.exe" "Adobe Crash Processor_.exe"

# Rename shortcuts from "Adobe Acrobat" to "Acrobat Reader"
# Only required if Acrobat Pro will also be installed as they share the same shortcut names
# & cmd.exe /c rename "C:\Users\Public\Desktop\Adobe Acrobat.lnk" "Acrobat Reader.lnk"
# & cmd.exe /c rename "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe Acrobat.lnk" "Acrobat Reader.lnk"


$InstalledVersion = GetVersionFromRegistry "Adobe Acrobat"

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

