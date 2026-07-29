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
$Vendor = "Irfanview"
$AppDesc = "A fast and compact image viewer and converter."
$AppName = "Irfanview ARM64"
$VendorURL = "https://www.irfanview.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Parse download page for latest version.
$Page = curl 'https://www.irfanview.com' -UseBasicParsing
## match operator populates the $matches variable.
$Page -match "Version (.*)</span>"
$LatestWebVersion = $matches[1]
$DLVersion = $LatestWebVersion -replace '\.',''

$InstallerName = "iview" + $DLVersion + "_arm64.zip"
$DownloadLink = "https://www.irfanview.info/files/" + $InstallerName

# Download installer - we have to use the curl.exe from System32 or you will get permission denied from the site
WriteLog "Downloading zip from $DownloadLink"
C:\Windows\System32\curl.exe $DownloadLink --referer "`"$DownloadLink`"" -o $DownloadPath\$InstallerName
Start-Sleep -Seconds 20

$InstalledVersion = $LatestWebVersion
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# IrfanView's arm64 setup exe exits 0 without installing anything when run with the
# documented silent switches, so install from the official ARM64 zip instead.
# The binaries are ARM64EC: they report x64 in the PE header (by design, for x64
# interop) but run natively on ARM64 - verified via the CHPE metadata pointer.
New-Item -Path "C:\Program Files" -Name "IrfanView" -ItemType Directory
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\Program Files\IrfanView"

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Resolve the exe by wildcard - the arm64 build's exe name is not guaranteed to be i_view64.exe
$IviewExe = (Get-ChildItem "C:\Program Files\IrfanView" -Filter "i_view*.exe" | Select-Object -First 1)

# The zip install creates no shortcuts - create the Start Menu and Desktop shortcuts
# the x64 installer would have created (the x64 recipe instead deletes the extras)
function CreateIrfanViewShortcut($shortcutPath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $IviewExe.FullName
    $shortcut.Save()
    WriteLog "Shortcut created: $shortcutPath"
}
New-Item -ItemType Directory -Force -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\IrfanView"
CreateIrfanViewShortcut "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\IrfanView\IrfanView.lnk"
CreateIrfanViewShortcut "$env:USERPROFILE\Desktop\IrfanView.lnk"

# Capture first launch to isolate user appdata folers
RunProcess $IviewExe.FullName $Null $False
Start-Sleep -Seconds 60
# Stop application
RunProcess "taskkill.exe" "/im $($IviewExe.Name)" $True

Start-Sleep -Seconds 90

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
