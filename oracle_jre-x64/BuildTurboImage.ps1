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
$Vendor = "Oracle"
$AppDesc = "Oracle's Java Runtime Environment allows you to run Java applications."
$AppName = "Java Runtime Environment 64-bit"
$VendorURL = "https://www.java.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion
    
##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Use the headless-extractor to get the download link
$url = "https://www.java.com/en/download/manual.jsp"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome-x64 --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

$javaLinks = $links | Where-Object { $_ -match "https://javadl\.oracle\.com/webapps/download/AutoDL\?BundleId=" }
$DownloadLink = $javaLinks[-1]

$InstallerName = "jre-windows-x64.exe"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "INSTALL_SILENT=1 NOSTARTMENU=1 WEB_ANALYTICS=0 SPONSORS=0 AUTO_UPDATE=0 EULA=0" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Delete C:\Program Files (x86)\Common Files\Java as it just contains the Java Updater files
Remove-Item -Path "C:\Program Files (x86)\Common Files\Java" -Recurse -Force

$InstalledVersion = GetVersionFromRegistry "Java"
# Remove any middle .0 from the version
$InstalledVersion = $InstalledVersion -replace '\.0\.', '.'

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

