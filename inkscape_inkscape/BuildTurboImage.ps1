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
$Vendor = "Inkscape"
$AppDesc = "Inkscape is professional quality vector graphics software."
$AppName = "Inkscape"
$VendorURL = "https://inkscape.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Parse download page for latest version.
$Page = curl 'https://inkscape.org/release/' -UseBasicParsing
## match operator populates the $matches variable.
((($Page.Links | Where-Object {$_.outerhtml -like "*Current Stable Version*"})[0].outerhtml) -match '<span class="info">(.*)</span>')
$LatestWebVersion = $matches[1]

# Parse release page for installer filename, which includes a hashed suffix.
$Page2 = curl "https://inkscape.org/release/inkscape-$LatestWebVersion/windows/32-bit/msi/dl/" -UseBasicParsing
$InstallerName = ($Page2.Links.href -like "*.msi").split("/")[-1]

# Compute download link
# Example: https://media.inkscape.org/dl/resources/file/inkscape-1.3.2_2023-11-25_091e20ef0f-x86.msi
$DownloadLink = "https://media.inkscape.org/dl/resources/file/$InstallerName"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

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

# Perform silent MSI installation
$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Capture first launch to isolate user appdata folders
RunProcess "C:\Program Files (x86)\Inkscape\bin\inkscape.exe" $Null $False
Start-Sleep -Seconds 60
# Stop application
RunProcess "taskkill.exe" "/im inkscape.exe" $True

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
