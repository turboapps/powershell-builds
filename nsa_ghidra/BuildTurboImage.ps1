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
$Vendor = "National Security Agency"
$AppDesc = "A software reverse engineering suite of tools developed by NSA's Research Directorate in support of the Cybersecurity mission."
$AppName = "Ghidra"
$VendorURL = "https://ghidra-sre.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest ZIP archive."

# Get main download page for application.
$Page = EdgeGetContent https://github.com/NationalSecurityAgency/ghidra/releases/latest


# Split the page content into lines
$PageLines = $Page -split "`n"

# Define a regular expression pattern to match installer filename
$InstallerNamePattern = '<a\s+href="(.*?ghidra.*?zip)".*?>'

# Filter and output lines containing matching links
foreach ($PageLine in $PageLines) {
    if ($PageLine -match $InstallerNamePattern) {
        $DownloadLink = "https://github.com" + $matches[1]  # Use the first link that matches the $InstallerNamePattern
        break
    }
}

# Download Installer
$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract ZIP archive.
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "C:\"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Copy the files instead of using Move-Item (not captured).
. xcopy /s/e/h (Get-Item "C:\ghidra*").FullName C:\ghidra\

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Create a preferences file to disable nag popups
$ConfigurationFolder = Join-Path "$env:appdata\ghidra" ($InstallerName.split("_")[0] + "_" + $InstallerName.split("_")[1] + "_" + $InstallerName.split("_")[2])

$ConfigurationFolder = Join-Path "$env:appdata\ghidra" "ghidra_11.1.1_PUBLIC"
$ConfigurationFile = Join-Path $ConfigurationFolder "preferences"

. mkdir "$ConfigurationFolder"
# Must use ASCII encoding for UTF8 without BOM or Ghidra will re-create the preferences file
"#User Preferences" | Out-File -encoding ASCII $ConfigurationFile
Add-Content -Path $ConfigurationFile -Value "GhidraShowWhatsNew=false"
Add-Content -Path $ConfigurationFile -Value "SHOW.HELP.NAVIGATION.AID=false"
Add-Content -Path $ConfigurationFile -Value "SHOW_TIPS=false"
Add-Content -Path $ConfigurationFile -Value "USER_AGREEMENT=ACCEPT"

# Get the latest version tag.
# Ghidra is not an installed application, but simply an extracted ZIP. We'll get the versioni from the installer name instead of registry.
$InstalledVersion = $InstallerName.split("_")[1]

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

