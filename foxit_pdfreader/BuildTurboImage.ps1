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
$Vendor = "Foxit"
$AppDesc = "View, annotate, form fill, and sign PDF across desktop, mobile, and web – no matter if you’re at the office, home, or on the go."
$AppName = "PDF Reader"
$VendorURL = "https://www.foxit.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$DownloadLink = 'https://www.foxit.com/downloads/latest.html?product=Foxit-Reader&platform=Windows&version=&package_type=&language=English&distID='

$InstallerName = "FoxitPDFReader.exe"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

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

# Perform Full install and include desktop shortcut
$ProcessExitCode = RunProcess $Installer "/VERYSILENT /NORESTART /TYPE=`"FULL`" /COMPONENTS=`"pdfviewer,ffse,ffaddin,ffspellcheck`" /TASKS=`"desktopicon,startmenufolder,displayinbrowser`" /ALLUSERS /CLOSEAPPLICATIONS /NOCANCEL /SUPPRESSMSGBOXES" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Stop and delete the update service
&sc.exe stop FoxitReaderUpdateService
&sc.exe delete FoxitReaderUpdateService
Remove-Item -Path "C:\Program Files (x86)\Common Files\Foxit\Foxit PDF Reader\FoxitPDFReaderUpdateService.exe" -Recurse -Force

# Disables updates, data collection, start page, ads, register prompt, welcome dialog, foxitsign prompt
&reg.exe import "$SupportFiles\prefs.reg"

# Delete uninstall shortcut
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Foxit PDF Reader\Uninstall Foxit PDF Reader.lnk" -Recurse -Force

# Copy the DefaultIcon reg key for the FoxitReader.PPDF ProgID to the FoxitReader.Document ProgID so they use the same icon
If (Test-Path HKLM:\SOFTWARE\Classes\FoxitReader.PPDF\DefaultIcon) {
    # Export the source registry key to a temporary file
    $tempFile = "$env:TEMP\foxit_software.reg"
    &reg.exe export "HKLM\SOFTWARE\Classes\FoxitReader.PPDF\DefaultIcon" $tempFile /y

    # Modify the exported .reg file to update the key path
    (Get-Content $tempFile) -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\FoxitReader.PPDF\\DefaultIcon', 'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\FoxitReader.Document\DefaultIcon' | Set-Content $tempFile

    # Import the modified .reg file back into the registry location then delete
    &reg.exe import $tempFile /reg:64
    Remove-Item $tempFile
}

# Duplicate the HKLM:\SOFTWARE\WOW6432Node\Foxit Software registry key to the 64bit key
# This is a temporary workaround to resolve the missing Default Programs captured by Turbo Studio - Remove on resolve of STD-4525
    # Export the source registry key to a temporary file
    $tempFile = "$env:TEMP\foxit_software.reg"
    &reg.exe export "HKLM\SOFTWARE\WOW6432Node\Foxit Software" $tempFile /y

    # Modify the exported .reg file to update the key path
    (Get-Content $tempFile) -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Foxit Software\\Foxit PDF Reader\\Capabilities', 'HKEY_LOCAL_MACHINE\SOFTWARE\Foxit Software\Foxit PDF Reader\Capabilities' | Set-Content $tempFile

    # Import the modified .reg file back into the registry location then delete
    &reg.exe import $tempFile /reg:64
    Remove-Item $tempFile

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
