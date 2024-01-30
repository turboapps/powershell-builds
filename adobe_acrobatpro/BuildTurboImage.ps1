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

$HubOrg = (Split-Path $scriptPath -Leaf) -replace '_', '/' # Set the repo name based on the folder path of the script assuming the folder is vendor_appname
$Vendor = "Adobe"
$AppDesc = "The all-in-one PDF and e-sign solution."
$AppName = "Acrobat Pro"
$VendorURL = "https://www.adobe.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$DownloadPath = "$env:USERPROFILE\Downloads"
$DesktopPath = "$env:USERPROFILE\Desktop"
$sikulixPath = "$DesktopPath\sikulix"
$IncludePath = Join-Path -Path $scriptPath -ChildPath "..\_INCLUDE"

# Copy the sikulix resources folder to the desktop
Copy-Item "$SupportFiles\Sikulix" -Destination $DesktopPath -Recurse
Copy-Item "$IncludePath\Sikulix" -Destination $DesktopPath -Recurse

# Wait for the warm up of the VM
Start-Sleep -Seconds 30

# Launch SikulixIDE to create and download packages from Adobe Admin Console
$ProcessExitCode = RunProcess "$sikulixPath\jre\bin\java.exe" "-jar $sikulixPath\sikulixide-2.0.5.jar -r $sikulixPath\test.sikuli" $True

# Extract the downloaded packages
Expand-Archive -Path $DownloadPath\CreativeCloudDesktop_x64_en_US_WIN_64.zip -DestinationPath $DownloadPath
Expand-Archive -Path $DownloadPath\AcrobatPro_x64_en_US_WIN_64.zip -DestinationPath $DownloadPath

# Delete the zip files to free up disk space
Remove-Item -Path "$DownloadPath\CreativeCloudDesktop_x64_en_US_WIN_64.zip" -Force
Remove-Item -Path "$DownloadPath\AcrobatPro_x64_en_US_WIN_64.zip" -Force

# Install the Create Cloud Desktop app before starting turbo studio capture as it will be a separate image
$ProcessExitCode = RunProcess "$DownloadPath\CreativeCloudDesktop_x64\Build\Setup.exe" "--silent" $True

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\AcrobatPro_x64\Build\Setup.exe" "--silent" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Set Adobe preferences https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunchWin10 /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\cCheckbox" /t REG_DWORD /d 1 /v iAppDoNotTakePDFOwnershipAtLaunch /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 10 /v iFTEVersion /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\AVAlert\FTEDialog" /t REG_DWORD /d 0 /v iLastCardShown /f /reg:64
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bToggleFTE /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bWhatsNewExp /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /t REG_DWORD /d 0 /v bProtectedMode /f
&reg.exe add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /t REG_DWORD /d 0 /v bUpdater /f

# Delete Adobe ARM service
&sc.exe stop adobearmservice
&sc.exe delete adobearmservice
# Delete Adobe update scheduled task
&schtasks /delete /tn "adobe acrobat update task" /f

$InstalledVersion = GetVersionFromRegistry "Adobe Acrobat"
# Add 20 to the version for the year
$InstalledVersion = "20" + $InstalledVersion


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

