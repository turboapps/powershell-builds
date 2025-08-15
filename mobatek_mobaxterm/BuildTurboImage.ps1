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
$Vendor = "Mobatek"
$AppDesc = "Enhanced terminal for Windows with X11 server, tabbed SSH client, network tools and much more."
$AppName = "MobaXterm"
$VendorURL = "https://mobaxterm.mobatek.net/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://mobaxterm.mobatek.net/download-home-edition.html' -UseBasicParsing

# Get installer link for latest version
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*installer*"})[0].href
Write-Host $DownloadLink

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]
Write-Host $InstallerName

$Archive = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract .zip
Expand-Archive -Path $Archive -DestinationPath "$DownloadPath\MobaXterm"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Find the extracted msi
Get-ChildItem -Path "$DownloadPath\MobaXterm" -Filter *.msi | ForEach-Object {
    $msi = $_.FullName
}

$ProcessExitCode = RunProcess "msiexec.exe" "/I $msi ALLUSERS=1 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Get the path to the latest MobaRTE.exe
$exePath = (Get-ChildItem -Path "C:\" -Filter "MobaRTE.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1).DirectoryName

# Copy the icons for the shell extensions
Copy-Item "$SupportFiles\MobaRTE_MAINICON.ico" -Destination $exePath -Force
Copy-Item "$SupportFiles\MobaRTE_MOBADIFF.ico" -Destination $exePath -Force
  
$InstalledVersion = GetVersionFromRegistry "MobaXterm"

#########################
## Stop Turbo Capture  ##
#########################

StopTurboCapture

######################
## Customize XAPPL  ##
######################

CustomizeTurboXappl "$SupportFiles\PostCaptureModifications.ps1"  # Helper script for XML changes to Xappl"

# Fix the &amp;quot in the shellextenions
$content = Get-Content $FinalXapplPath -Raw
$content = $content -replace '&amp;quot;', '&quot;'
Set-Content $FinalXapplPath -Value $content

#########################
## Build Turbo Image   ##
#########################

BuildTurboSvmImage

########################
## Push Turbo Image   ##
########################

PushImage $InstalledVersion
