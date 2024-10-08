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
$Vendor = "Shining Light Productions"
$AppDesc = "The OpenSSL software library is a robust, commercial-grade, full-featured toolkit for general-purpose cryptography and secure communication."
$AppName = "OpenSSL Light"
$VendorURL = "https://slproweb.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Use the headless-extractor to get the download link
$url = "https://slproweb.com/products/Win32OpenSSL.html"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

# Loop through the lines and find the first .msi link
$DownloadLink = $null
foreach ($link in $links) {
    if ($link -match "Win64OpenSSL_Light.*\.msi$") {
        $DownloadLink = $link
        break
    }
}

$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = Get-MsiProductVersion "$Installer"
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

# Donwload the VC++2015-2022 x64 Redistributable
WriteLog "Downloading the VCRedist installer."
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile "$DownloadPath\vc_redist.x64.exe"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the VCRedist
$ProcessExitCode = RunProcess "$DownloadPath\vc_redist.x64.exe" "/S" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Add "C:\Program Files\OpenSSL-Win64\bin" to the PATH environment variable
[System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Program Files\OpenSSL-Win64\bin", [System.EnvironmentVariableTarget]::Machine)


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
