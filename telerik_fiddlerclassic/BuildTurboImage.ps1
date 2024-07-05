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
$Vendor = "Telerik"
$AppDesc = "The Original and Free Web Debugging Proxy Tool Exclusively for Windows."
$AppName = "Fiddler Classic"
$VendorURL = "https://www.telerik.com/fiddler/fiddler-classic"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Get installer link for latest version
$DownloadLink = "https://api.getfiddler.com/fc/latest"

$InstallerName = "FiddlerSetup.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = Get-VersionFromExe $Installer
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the application silently using cmd to run the installer otherwise the /D param doesn't work
$ProcessExitCode = RunProcess "cmd.exe" "/c $Installer /S /D=%SystemDrive%\Fiddler" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

&reg.exe add "HKCU\SOFTWARE\Microsoft\Fiddler2" /v SendTelemetry /t REG_SZ /d False /f # disable participation in Improvement Program
&reg.exe add "HKCU\SOFTWARE\Microsoft\Fiddler2" /v CheckForUpdates /t REG_SZ /d False /f # disable check for updates
&reg.exe add "HKCU\SOFTWARE\Microsoft\Fiddler2\Prefs\.default" /v fiddler.updater.offerbetabuilds /t REG_SZ /d False /f # disable offer for beta versions
&reg.exe add "HKCU\SOFTWARE\Microsoft\Fiddler2\Prefs\.default" /v fiddler.proxy.warnaboutappcontainers /t REG_SZ /d False /f # disable first launch AppContainer message

# Fix the icon for the Fiddler shortcut
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Fiddler Classic.lnk")
$shortcut.IconLocation = "$env:SystemDrive\Fiddler\App.ico"
$shortcut.Save()

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
