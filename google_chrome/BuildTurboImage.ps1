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
$Vendor = "Google"
$AppDesc = "Free web browser developed by Google, enhanced for performance and privacy."
$AppName = "Chrome"
$VendorURL = "https://google.com/chrome"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
## Simplified link is https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi. However, our link disables browser usage stats and installs for all users.
$DownloadLink = "https://dl.google.com/tag/s/appguid={00000000-0000-0000-0000-000000000000}&iid={00000000-0000-0000-0000-000000000000}&lang=$language&browser=3&usagestats=0&appname=Google%20Chrome&installdataindex=defaultbrowser&needsadmin=prefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi"

# Name of the downloaded installer file
$InstallerName = "googlechromestandaloneenterprise.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Copy initial_prefernces file - this file doesn't currently contain any changes to defaults but allows for future changes if required.
Copy-Item "$SupportFiles\initial_preferences" -Destination "C:\Program Files (x86)\Google\Chrome\Application\"  -Force
# Copy Google folder to localappdata - this folder contains files to prevent the Google Welcome page on first launch.
Copy-Item -Path "$SupportFiles\Google" -Destination "$env:LOCALAPPDATA\" -Recurse -Force

# Create "Chrome Apps" folder in Start Menu - creating this folder will prevent google app shortcuts from getting created
Copy-Item -Path "$SupportFiles\Chrome Apps" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\" -Recurse -Force

# Kill updater.exe if running
taskkill.exe /f /im updater.exe /t

# Delete Google Update
# Get all services matching the pattern "google*" and "gupdate*"
$pattern = "^(google|gupdate)"
$services = Get-Service | Where-Object { $_.Name -match $pattern }

# Iterate through each service and stop it if it's running, then remove it
foreach ($service in $services) {
    if ($service.Status -eq "Running") {
        sc.exe stop $service.ServiceName
    }
    sc.exe delete $service.ServiceName
}

# Delete Google update folders
Remove-Item -Path "C:\Program Files (x86)\Google\Update\*" -Recurse -Force
Remove-Item -Path "C:\Program Files (x86)\Google\GoogleUpdater\*" -Recurse -Force

$InstalledVersion = GetVersionFromRegistry "Google Chrome"

# Delete installer files
Remove-Item -Path "C:\Program Files (x86)\Google\Chrome\Application\$InstalledVersion\Installer\*" -Recurse -Force

# Set the policy key to prevent the default browser banner
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f
&reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v PrivacySandboxPromptEnabled /t REG_DWORD /d 0 /f

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

