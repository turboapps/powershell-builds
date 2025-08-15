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
$Vendor = "NoMachine"
$AppDesc = "Enterprise Client enables fast and secure access to your remote PC or desktop computer where you have installed one of the NoMachine server products."
$AppName = "NoMachine Enterprise Client"
$VendorURL = "https://www.nomachine.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Use the headless-extractor to get the download link
$url = "https://download.nomachine.com/download/?id=6&platform=windows"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- -File C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

# Define a regular expression pattern
$pattern = 'x64.exe'

# Filter and output lines containing matching links
foreach ($line in $links) {
    if ($line -match $pattern) {
        $DownloadLink = $line  # Directly use the matching URL
    }
}

$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Get the latest version tag.
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

$ProcessExitCode = RunProcess $Installer "/VERYSILENT /NORESTART /TYPE=`"FULL`" /MERGETASKS=`"desktopicon`" /ALLUSERS /NOCLOSEAPPLICATIONS /NOCANCEL /SUPPRESSMSGBOXES" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Copy the NoMachine folder containing UPDATE file to disable update checks to programdata
Copy-Item -Path "$SupportFiles\NoMachine" -Destination "$env:ALLUSERSPROFILE\" -Recurse -Force

###############################################################
# Modify the player.cfg file to suppress first launch prompts #
###############################################################

# Launch nxrunner.exe to create player.cfg file
. "C:\Program Files\NoMachine Enterprise Client\bin\nxrunner.exe"

# Wait for player.cfg file to be created
Start-Sleep -Seconds 5

# Make sure the file exists
$cfgPath = Join-Path $env:USERPROFILE ".nx\config\player.cfg"
if (-Not (Test-Path $cfgPath)) {
    WriteLog "Config file not found: $cfgPath"
    exit 1
}

# Load the XML
[xml]$xml = Get-Content $cfgPath

# List of keys to check
$keysToChange = @(
    "Show desktop sharing tutorial",
    "Show add machine tutorial",
    "Show address retrieving tutorial",
    "Show NoMachine Network user tutorial"
)

# Loop through matching option nodes and set value to false if true
foreach ($key in $keysToChange) {
    $node = $xml.SelectSingleNode("//option[@key='$key']")
    if ($node -and $node.value -eq "true") {
        $node.value = "false"
        WriteLog "Changed '$key' to false"
    }
}

# Save the updated XML back to the file
$xml.Save($cfgPath)
WriteLog "Done updating $cfgPath"

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

