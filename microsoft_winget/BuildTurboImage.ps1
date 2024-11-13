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
$AppDesc = "The winget command line tool enables users to discover, install, upgrade, remove and configure applications on Windows 10 and Windows 11 computers. "
$AppName = "winget"
$VendorURL = "https://learn.microsoft.com/en-us/windows/package-manager/winget/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Donwload the VC++2015-2022 x64 Redistributable
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile "$DownloadPath\vc_redist.x64.exe"

# Download the required installers
$progressPreference = 'silentlyContinue'
Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile "$DownloadPath\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$DownloadPath\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx -OutFile "$DownloadPath\Microsoft.VCLibs.x86.14.00.Desktop.appx"
Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile "$DownloadPath\Microsoft.UI.Xaml.2.7.x64.appx"
Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile "$DownloadPath\Microsoft.UI.Xaml.2.8.x64.appx"
Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x86.appx -OutFile "$DownloadPath\Microsoft.UI.Xaml.2.8.x86.appx"


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

# Install the VCRedist
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.x64.exe" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Make sure there is no policy blocking Windows Store apps
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore /v DisableStoreApps /t REG_DWORD /d 0 /f

WriteLog "Installing Winget and depdencies"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.VCLibs.x86.14.00.Desktop.appx"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.UI.Xaml.2.7.x64.appx"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.UI.Xaml.2.8.x64.appx"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.UI.Xaml.2.8.x86.appx"
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath  "$DownloadPath\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"


################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Take ownership of C:\Program Files\WindowsApps
takeown /f "C:\Program Files\WindowsApps" /r /d y

# Grant Administrators Full control to C:\Program Files\WindowsApps
icacls "C:\Program Files\WindowsApps" /grant administrators:F /t /c /q

# Get the path to the latest winget.exe
$exePath = Get-ChildItem -Path "C:\Program Files\WindowsApps" -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1 -ExpandProperty FullName

# Get the version
$winget_ver = . $exePath -v
$InstalledVersion = $winget_ver -replace '^v', ''

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

