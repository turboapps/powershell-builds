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

$HubOrg = "adobe/adobereader-x64"  # Set this for each package
$Vendor = "Adobe"
$AppDesc = "View, print, search, sign, verify, and collaborate on PDF documents."
$AppName = "Acrobat Reader (64-bit)"
$VendorURL = "https://adboe.com"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

## Determine the latest version of installer
$url = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
$webContent = Invoke-WebRequest -Uri $url -UseBasicParsing
$lines = $webContent.Content.Split("`n")

# Look for the first instance of <link rel="next" in the source page
foreach ($line in $lines) {
    if ($line -match '<link rel="next"') {

        $output = $line 
        break
    }
}

# Use regular expression to match a sequence of digits separated by dots
$pattern = "\d+(?:\.\d+)*"
$matches = [regex]::Matches($output, $pattern)

# Extract the first match as the version text
$version = $matches[0].Value
$version = $version.replace('.','')


# Get installer link for latest version
$DownloadLink = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/" + $version + "/AcroRdrDCx64" + $version + "_MUI.exe"
# Folder the installer will be downloaded to
$DownloadPath = New-Item -Path $scriptPath -Name "Installer" -ItemType "directory" -Force # create an Installer directory on the desktop for the donwnload
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

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/sAll /rs /l /msi /qb-! /norestart ALLUSERS=1 EULA_ACCEPT=YES SUPPRESS_APP_LAUNCH=YES" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

&reg.exe add "HKCU\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunchWin10 /f
&reg.exe add "HKCU\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunch /f
&reg.exe add "HKCU\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 10 /v iFTEVersion /f
&reg.exe add "HKCU\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 0 /v iLastCardShown /f
&reg.exe add "HKCU\SOFTWARE\Adobe\Adobe Acrobat\DC\Privileged" /t REG_DWORD /d 0 /v bProtectedMode /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bUpdater /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 1 /v bAcroSuppressUpsell /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /t REG_DWORD /d 0 /v bUpdater /f

# Delete Adobe ARM service
&sc.exe stop adobearmservice
&sc.exe delete adobearmservice
# Delete Adobe update scheduled task
&schtasks /delete /tn "adobe acrobat update task" /f
# Cleanup installer files
&cmd.exe /c rmdir /S /Q "C:\program files\common files\adobe\acrobat\setup"

# Get the installed version from the registry
foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
    $name = (Get-ItemProperty $subkey.PSPath).DisplayName
    if ($name -eq "Adobe Acrobat (64-bit)") {
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

