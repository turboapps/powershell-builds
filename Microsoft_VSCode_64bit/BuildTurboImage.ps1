## This script will download the latest installer and create a Turbo SVM image in @DESKTOP@\Package\TurboCapture.
## The script is logged to @DESKTOP@\Package\Log.
## The turbo project and build are saved  to @DESKTOP@\Package\TurboCapture.
## Usage:
## Run this script from an elevated cmd prompt: Powershell -ExecutionPolicy Bypass -File <path>\scriptname.ps1
## Required:  You must have your Turbo Studio license in a "License.txt" file in an "Include" folder in the same folder as this script.
## Required:  You must have the "GlobalBuildScript.ps1" file in an "Include" folder in the same folder as this script.
## Required:  Any files used to customize the configuration should be a "Support Files" folder located in the same folder as this script.

$scriptPath = $PSScriptRoot  # The folder path the script was launched from
$GlobalScriptPath = Join-Path -Path $scriptPath -ChildPath "..\_INCLUDE\GlobalBuildScript.ps1"  #Get the path to the GlobalBuildScript.ps1
. $GlobalScriptPath  # Include the script that contains global variables and functions
$SupportFiles = "$scriptPath\SupportFiles"  # The folder path contains files specific to this application build


###################################
## Define app specific variables ##
###################################
# These values will used to set the Metadata for the turbo image.

$HubOrg = "microsoft/vscode-x64"  # Set this for each package
$Vendor = "Microsoft"
$AppDesc = "Build and debug modern web and cloud applications."
$AppName = "Microsoft VSCode (64-bit)"
$VendorURL = "https://code.visualstudio.com/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://update.code.visualstudio.com/latest/win32-x64/stable"

# Name of the downloaded installer file
$InstallerName = "VSCodeSetup-x64.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "/VERYSILENT /NORESTART /MERGETASKS=!runcode" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Copy Code folder to appdata - this folder contains the settings.json configuration file that disables updates and telemetry
Copy-Item -Path "$SupportFiles\Code" -Destination "$env:APPDATA\" -Recurse -Force

# Get the installed version from the registry
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$subKey = $key.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
$subKeyNames = $subKey.GetSubKeyNames()
foreach($name in $subKeyNames) {
    $sub = $subKey.OpenSubKey($name)
    $displayName = $sub.GetValue("DisplayName")
    if($displayName -like "*Microsoft Visual Studio Code*") {
        # Output the key name and display name
        $InstalledVersion = $sub.GetValue("DisplayVersion")
        Write-Output "Key: $name, Display Version: $InstalledVersion"
    }
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

