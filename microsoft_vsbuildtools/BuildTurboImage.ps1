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
$Vendor = "Microsoft"
$AppDesc = "The Visual Studio Build Tools allows you to build native and managed MSBuild-based applications without requiring the Visual Studio IDE. There are options to install the Visual C++ compilers and libraries, MFC, ATL, and C++/CLI support."
$AppName = "Visual Studio Build Tools 2022"
$VendorURL = "https://visualstudio.microsoft.com/visual-cpp-build-tools/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# Get installer link for latest version
# The aka.ms link always resolves to the current VS 2022 (channel 17) release bootstrapper.
# Build Tools for the next major version (18) is only published on the Insiders/Preview channel, so this build stays on 17.
$DownloadLink = "https://aka.ms/vs/17/release/vs_BuildTools.exe"

# Name of the downloaded installer file
$InstallerName = "vs_BuildTools.exe"

# Download the install file
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Workloads to install. Only what is listed here (plus required dependencies) gets installed.
# Component IDs: https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
$Workloads = @(
    "Microsoft.VisualStudio.Workload.MSBuildTools",  # MSBuild Tools
    "Microsoft.VisualStudio.Workload.VCTools"        # Desktop development with C++ (MSVC toolset, Windows SDK and CMake come in with --includeRecommended)
)
$AddArgs = ($Workloads | ForEach-Object { "--add $_" }) -join " "

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# VS-installer bootstrapper silent install; --wait keeps the bootstrapper alive until setup finishes
# --nocache stops the downloaded payloads from being kept in @APPDATACOMMON@\Microsoft\VisualStudio\Packages and captured into the image
$ProcessExitCode = RunProcess "$Installer" "--quiet --norestart --wait --nocache $AddArgs --includeRecommended" $True
# 3010 = ERROR_SUCCESS_REBOOT_REQUIRED: install succeeded, only a reboot is pending - treat as success
if ($ProcessExitCode -eq 3010) { $ProcessExitCode = 0 }
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Get the installed version (eg 17.14.39) from vswhere, which is installed alongside the VS Installer.
# The Uninstall registry key only holds the build number (eg 17.14.37614.0) so it is not used here.
$VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$InstalledVersion = & "$VsWhere" -products Microsoft.VisualStudio.Product.BuildTools -property catalog_productDisplayVersion
$InstalledVersion = [regex]::Match("$InstalledVersion", '^\d+(\.\d+)+').Value

if ([string]::IsNullOrWhiteSpace($InstalledVersion)) {
    # Fall back to the release channel manifest - the same source VersionCheck.ps1 uses
    WriteLog "vswhere did not return a version. Falling back to the release channel manifest."
    $Channel = Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/channel" -UseBasicParsing
    $InstalledVersion = [regex]::Match("$($Channel.info.productDisplayVersion)", '^\d+(\.\d+)+').Value
}

$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"
WriteLog "Installed Version: $InstalledVersion"

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

