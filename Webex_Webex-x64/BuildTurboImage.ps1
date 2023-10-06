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
$GlobalScriptPath = Join-Path -Path $scriptPath -ChildPath "..\_INCLUDE\GlobalBuildScript.ps1"  #Get the path to the GlobalBuildScript.ps1
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

$HubOrg = "cisco/webex-x64"  # Set this for each package
$Vendor = "Cisco Systems"
$AppDesc = "Webex is your one place to call, message, meet."
$AppName = "Webex 64-bit"
$VendorURL = "https://www.webex.com/"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://binaries.webex.com/WebexTeamsDesktop-Windows-Gold/Webex_en.msi"

# Name of the downloaded installer file
$InstallerName = "Webex_en.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "msiexec.exe" "/I $Installer ALLUSERS=1 AUTOUPGRADEENABLED=0 ENABLEVDI=2 /qn" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

$ProcessExitCode = RunProcess "C:\Program Files\Cisco Spark\WebView2Runtime\MicrosoftEdgeWebview2Setup.exe" "/silent /install" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Launch Webex then send the Enter key to accept the agreement
$ProcessExitCode = RunProcess "C:\Program Files\Cisco Spark\CiscoCollabHost.exe" $False
Start-Sleep -Seconds 5
$wshell = New-Object -ComObject wscript.shell;
$wshell.AppActivate('Webex End User License Agreement')
Start-Sleep -Seconds 1
$wshell.SendKeys('{ENTER}')

# Get the installed version from the registry
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$subKey = $key.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
$subKeyNames = $subKey.GetSubKeyNames()
foreach($name in $subKeyNames) {
    $sub = $subKey.OpenSubKey($name)
    $displayName = $sub.GetValue("DisplayName")
    if($displayName -like "*Webex*") {
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

