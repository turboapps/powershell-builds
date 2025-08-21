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
$Vendor = "cygwin"
$AppDesc = "Collection of GNU and Open Source tools which provide functionality similar to a Linux distribution on Windows."
$AppName = "cygwin"
$VendorURL = "https://cygwin.com/index.html"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = Invoke-WebRequest 'https://cygwin.com/index.html' -UseBasicParsing

# Get installer link for latest version
# Use regex to find the first cygwin-announce link and capture the link text
if ($Page.Content -match '<a[^>]+href="([^"]*\.exe)"') {
    $LatestInstallerUrl = "https://cygwin.com/$($matches[1])"
}
WriteLog $LatestInstallerUrl

# Name of the downloaded installer file
$InstallerName = $LatestInstallerUrl.Split("/")[-1]

$Installer = DownloadInstaller $LatestInstallerUrl $DownloadPath $InstallerName

$InstalledVersion

# Use regex to find the first cygwin-announce link and capture the link text
if ($Page.Content -match '<a[^>]+href="[^"]*cygwin-announce[^"]*"[^>]*>\s*([^<]+)\s*</a>') {
    $InstalledVersion = $matches[1]
}
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

cd c:\temp
$ProcessExitCode = RunProcess "$Installer" "--quiet-mode --local-package-dir C:\temp\cygwin --root C:\Cygwin64 --arch x86_64 --site http://cygwin.mirror.constant.com --categories Base --packages make,openssh --force-current" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Copy the installer to include in the capture
Copy-Item -Path $Installer -Destination "C:\Cygwin64\setup-x86_64.exe" -Force

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Create shortcut for Cygwin64 Terminal
$exePath = "C:\Cygwin64\bin\mintty.exe"
$arguments = '-i /Cygwin-Terminal.ico -'
$iconPath = "C:\Cygwin64\Cygwin.ico"

# Create Start Menu shortcut
New-Item -ItemType Directory -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Cygwin" | Out-Null
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Cygwin\Cygwin64 Terminal.lnk"


$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.Arguments = $arguments
$shortcut.IconLocation = $iconPath
$shortcut.Save()

# Copy shortcut to All Users Desktop
$publicDesktop = "C:\Users\Public\Desktop"
Copy-Item -Path $shortcutPath -Destination $publicDesktop -Force

WriteLog "Start menu and desktop shortcuts created: $shortcutPath"

# Create shortcut for Cygwin Installer
$exePath = "C:\Cygwin64\setup-x86_64.exe"
$iconPath = "C:\Cygwin64\Cygwin.ico"

# Create Start Menu shortcut
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Cygwin\Cygwin64 Setup.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.IconLocation = $iconPath
$shortcut.Save()

WriteLog "Start menu shortcut created: $shortcutPath"

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
