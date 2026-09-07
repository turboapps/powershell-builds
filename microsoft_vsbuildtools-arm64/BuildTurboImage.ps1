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
## Required:  This script must run on a Windows on ARM64 machine. The VS Installer only lays down the native ARM64-hosted
##            MSVC toolset (VC\Tools\MSVC\<ver>\bin\Hostarm64) and the ARM64 MSBuild when the capture machine itself is ARM64.
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

# Check that the OS is Windows on ARM64. The OS architecture is checked rather than PROCESSOR_ARCHITECTURE because
# that variable reports AMD64 when PowerShell itself is running as an emulated x64 process on an ARM64 machine.
$OsArch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
if ($OsArch -notmatch 'ARM') {
    WriteLog "This script must run on a Windows ARM64 machine (detected: $OsArch). The ARM64 toolset is only installed on ARM64 hosts."
    # Exit the current script
    exit
}

###################################
## Define app specific variables ##
###################################
# These values will used to set the Metadata for the turbo image.

$HubOrg = (Split-Path $scriptPath -Leaf) -replace '_', '/' # Set the repo name based on the folder path of the script assuming the folder is vendor_appname
$Vendor = "Microsoft"
$AppDesc = "The Visual Studio Build Tools allows you to build native and managed MSBuild-based applications without requiring the Visual Studio IDE. This image contains the MSVC ARM64/ARM64EC compilers and libraries for Windows on ARM."
$AppName = "Visual Studio Build Tools 2022 ARM64"
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
# The aka.ms link always resolves to the current VS 2022 (channel 17) release bootstrapper. There is no separate ARM64
# bootstrapper - the same vs_BuildTools.exe detects the ARM64 host and installs the ARM64 build of the VS Installer.
# Build Tools for the next major version (18) is only published on the Insiders/Preview channel, so this build stays on 17.
$DownloadLink = "https://aka.ms/vs/17/release/vs_BuildTools.exe"

# Name of the downloaded installer file
$InstallerName = "vs_BuildTools.exe"

# Download the install file
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Components to install. Only what is listed here (plus required dependencies) gets installed.
# The x64 image uses the "Desktop development with C++" workload, but that workload hard-wires the x86/x64 MSVC toolset
# (Microsoft.VisualStudio.Component.VC.Tools.x86.x64), so the ARM64 image selects the C++ components individually instead.
# Component IDs: https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
$Components = @(
    "Microsoft.VisualStudio.Workload.MSBuildTools",           # MSBuild Tools (includes the native ARM64 MSBuild on ARM64 hosts)
    "Microsoft.VisualStudio.Component.VC.CoreBuildTools",     # C++ Build Tools core features (vcvarsall.bat, VsDevCmd C++ targets, MSBuild C++ props)
    "Microsoft.VisualStudio.Component.VC.Tools.ARM64",        # MSVC v143 - VS 2022 C++ ARM64/ARM64EC build tools (Latest) - also pulls in VC.Tools.ARM64EC
    "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",   # C++ 2022 Redistributable Update (ARM64 build on ARM64 hosts)
    "Microsoft.VisualStudio.Component.Windows11SDK.26100"     # Windows 11 SDK (10.0.26100) - headers, ARM64 import libs and tools
)
# Not included on purpose:
#   Microsoft.VisualStudio.Component.VC.CMake.Project - depends on the x86/x64 MSVC toolset and the bundled CMake/Ninja binaries are x64-only
#   Microsoft.VisualStudio.Component.VC.ASAN         - AddressSanitizer runtimes are only shipped for x86/x64
$AddArgs = ($Components | ForEach-Object { "--add $_" }) -join " "

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
# --includeRecommended is not used: components are listed explicitly above so the x64 toolset does not get pulled in as a recommendation
$ProcessExitCode = RunProcess "$Installer" "--quiet --norestart --wait --nocache $AddArgs" $True
# 3010 = ERROR_SUCCESS_REBOOT_REQUIRED: install succeeded, only a reboot is pending - treat as success
if ($ProcessExitCode -eq 3010) { $ProcessExitCode = 0 }
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Get the installed version (eg 17.14.39) from vswhere, which is installed alongside the VS Installer.
# The VS Installer lives in Program Files (x86) on ARM64 Windows as well.
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

# Confirm the native ARM64-hosted compiler was installed. Without it the image would only contain cross compilers.
$HostArm64Compiler = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*\bin\Hostarm64\arm64\cl.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($HostArm64Compiler) {
    WriteLog "Found native ARM64 compiler: $($HostArm64Compiler.FullName)"
} else {
    WriteLog "WARNING: Hostarm64\arm64\cl.exe was not found under the BuildTools MSVC folder."
}

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
