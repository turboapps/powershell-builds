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
$Vendor = "Microsoft"
$AppDesc = "Meet, chat, and share content with anyone from anywhere in an easy and reliable way."
$AppName = "Teams 64-bit"
$VendorURL = "https://teams.microsoft.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Download the latest MSIX
$DownloadLink = "https://go.microsoft.com/fwlink/?linkid=2196106"
$InstallerName = "Teams_windows_x64.msix"
$MSIX = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Download the latest teamsbootstrapper
$DownloadLink = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
$InstallerName = "teamsbootstrapper.exe"
$Bootstrapper = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

# Replace the SnapshotSettings_21.xml file to include C:\Program Files\WindowsApps folder in the capture
New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA\Turbo.net
Copy-Item -Path "$SupportFiles\Turbo Studio 24" -Destination "$env:LOCALAPPDATA\Turbo.net" -Recurse -Force

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install Teams
$ProcessExitCode = RunProcess $Bootstrapper "-p -o $MSIX" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Get the Teams installdir
$TeamsInstallDir = (Get-AppxPackage | Where-Object {$_.Name -like "MSTeams*"}).InstallLocation
$TeamsEXE = "$TeamsInstallDir\ms-teams.exe"

# Get the version of the MicrosoftTeamsMeetingAddinInstaller
$TeamsAddInVersion = (Get-AppLockerFileInformation -Path "$TeamsInstallDir\MicrosoftTeamsMeetingAddinInstaller.MSI").Publisher.BinaryVersion

# Install the MicrosoftTeamsMeetingAddinInstaller
$ProcessExitCode = RunProcess "msiexec.exe" "/i `"$TeamsInstallDir\MicrosoftTeamsMeetingAddinInstaller.msi`" ALLUSERS=1 /qn /norestart TARGETDIR=`"C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\$TeamsAddInVersion\`"" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Disable auto updates
&reg.exe add "HKLM\Software\Microsoft\Teams" /t REG_DWORD /d 1 /v disableAutoUpdate /f /reg:64



################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Write registry keys to create the URL Protocol handlers
New-Item -Path "HKCU:\Software\Classes\msteams\shell\open\command" -Force
New-ItemProperty -Path "HKCU:\Software\Classes\msteams" -Name "(Default)" -Value "URL:msteams" -PropertyType String
New-ItemProperty -Path "HKCU:\Software\Classes\msteams" -Name "URL Protocol" -PropertyType String
New-ItemProperty -Path "HKCU:\Software\Classes\msteams\shell\open\command" -Name "(Default)" -Value "`"$TeamsEXE`" `"%1`"" -PropertyType String -Force

New-Item -Path "HKCU:\Software\Classes\ms-teams\shell\open\command" -Force
New-ItemProperty -Path "HKCU:\Software\Classes\ms-teams" -Name "(Default)" -Value "URL:msteams" -PropertyType String
New-ItemProperty -Path "HKCU:\Software\Classes\ms-teams" -Name "URL Protocol" -PropertyType String
New-ItemProperty -Path "HKCU:\Software\Classes\ms-teams\shell\open\command" -Name "(Default)" -Value "`"$TeamsEXE`" `"%1`"" -PropertyType String -Force

# Write this key to isolate to the container to prevent Teams lauching to a blank white window
New-Item -Path "HKCU:\Software\Classes\TeamsURL"

function CreateTeamsShortcut($shortcutPath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TeamsEXE
    $shortcut.Save()

    WriteLog "Start menu shortcut created: $shortcutPath"
}

# Create Start Menu shortcut
CreateTeamsShortcut "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Teams (work or school).lnk"
# Create Desktop shortcut
CreateTeamsShortcut "$env:USERPROFILE\Desktop\Microsoft Teams (work or school).lnk"

$InstalledVersion = Get-VersionFromExe $TeamsEXE

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

