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
$Vendor = "TigerVNC"
$AppDesc = "TigerVNC Viewer is a remote desktop client that lets you connect to and control another computer over a network using the VNC (Virtual Network Computing) protocol."
$AppName = "TigerVNC Viewer"
$VendorURL = "https://tigervnc.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://github.com/TigerVNC/tigervnc/releases' -UseBasicParsing

# Get installer link for latest version
$LatestInstallerLink = ($Page.Links | Where-Object {$_.href -like "*stable*"})[0].href
WriteLog $LatestInstallerLink 
$Page = curl $LatestInstallerLink -UseBasicParsing

# Get installer link for latest version
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*vncviewer64*"})[0].href
WriteLog $DownloadLink

# Get the final resolved URL (actual .exe file)
$req = [System.Net.WebRequest]::Create($DownloadLink)
$req.Method = "HEAD"
$req.AllowAutoRedirect = $true
$resp = $req.GetResponse()
$finalRedirect = $resp.ResponseUri.AbsoluteUri
$resp.Close()

# Always trim everything after the first ".exe"
if ($finalRedirect -match "(?i)(.+?\.exe)") {
    $finalRedirect = $matches[1]
}

WriteLog $finalRedirect

# Name of the downloaded installer file
$InstallerName = $finalRedirect.Split("/")[-1]
WriteLog $InstallerName

$Installer = DownloadInstaller $finalRedirect $DownloadPath $InstallerName

# Get the latest version tag.
$InstalledVersion = Get-VersionFromExe $Installer
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

# Fail the build if $InstalledVersion is null
if (-not $InstalledVersion) {
    WriteLog "InstalledVersion is null or empty. Exiting."
    exit -1
}

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$dest = "$env:ProgramFiles\TigerVNC"
New-Item -Path $dest -ItemType Directory -Force | Out-Null

# Copy the installer and rename it as vncviewer.exe
Copy-Item -Path $Installer -Destination "$dest\vncviewer.exe" -Force

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

$exePath = "$env:ProgramFiles\TigerVNC\vncviewer.exe"

# Create Start Menu shortcut
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\TigerVNC Viewer.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.Save()

# Copy shortcut to All Users Desktop
$publicDesktop = "C:\Users\Public\Desktop"
Copy-Item -Path $shortcutPath -Destination $publicDesktop -Force

WriteLog "Start menu and desktop shortcuts created: $shortcutPath"


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
