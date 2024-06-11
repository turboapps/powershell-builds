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
$Vendor = "Videolan"
$AppDesc = "An open source multimedia framework, player, and server."
$AppName = "VLC"
$VendorURL = "www.videolan.org/vlc/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://www.videolan.org/vlc/' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*win64*"})[0].href
$InstallerName = $LatestInstaller.Split("/")[-1]
$InstallerVersion = $InstallerName.Split("-")[1]

# Name of the downloaded installer file
$DownloadLink = "https://lesnet.mm.fcix.net/videolan-ftp/vlc/" + $InstallerVersion + "/win64/vlc-" + $InstallerVersion +"-win64.exe"
$InstallerName = $DownloadLink.Split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$Installer" "/L=1033 /S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Delete web shortcuts from the start menu
&cmd /c del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Documentation.lnk"
&cmd /c del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\VideoLAN website.lnk"
&cmd /c del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Release Notes.lnk"

# Launch VLC then send keys to disable Update check and send usage information
&"C:\Program Files\VideoLAN\VLC\vlc.exe"
Start-Sleep -Seconds 5
$wshell = New-Object -ComObject wscript.shell;
$wshell.AppActivate('Privacy and Network Access Policy')
Start-Sleep -Seconds 1
$wshell.SendKeys('{TAB}')
$wshell.SendKeys(' ')
$wshell.SendKeys('{TAB}')
$wshell.SendKeys(' ')
$wshell.SendKeys('{TAB}')
$wshell.SendKeys(' ')

# Kill the vlc.exe process
&cmd.exe /c taskkill /F /IM vlc.exe /T

$InstalledVersion = GetVersionFromRegistry "VLC"

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

