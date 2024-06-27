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
$Vendor = "Adobe"
$AppDesc = "Quickly create and publish web pages almost anywhere with Adobe Dreamweaver responsive web design software that supports HTML, CSS, JavaScript, and more."
$AppName = "Dreamweaver"
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
$IncludePath = Join-Path -Path $scriptPath -ChildPath "..\!include"

# Copy the sikulix resources folder to the desktop
if (!(Test-Path "$DesktopPath\Sikulix")) {
    Copy-Item "$SupportFiles\Sikulix" -Destination $DesktopPath -Recurse -Force
    Copy-Item "$IncludePath\util.sikuli" -Destination $sikulixPath -Recurse -Force
}

# Wait for the warm up of the VM
Start-Sleep -Seconds 30

# Pull down the sikulix and openjdk turbo images from turbo.net hub if they are not already part of the image
$turboArgs = "config --domain=turbo.net"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
$turboArgs = "pull xvm,base,sikulix/sikulixide,microsoft/openjdk"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True

# Launch SikulixIDE to get the latest version from Adobe Admin Console
$turboArgs = "try sikulixide --using=microsoft/openjdk --offline --disable=spawnvm --isolate=merge-user --startup-file=java -- -jar @SYSDRIVE@\SikulixIDE\sikulixide-2.0.5.jar -r $sikulixPath\build.sikuli -f $env:userprofile\desktop\build-sikulix-log.txt"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Extract the downloaded packages
Expand-Archive -Path $DownloadPath\CreativeCloudDesktop_x64_en_US_WIN_64.zip -DestinationPath $DownloadPath
Expand-Archive -Path $DownloadPath\Dreamweaver_x64_en_US_WIN_64.zip -DestinationPath $DownloadPath

# Delete the zip files to free up disk space
Remove-Item -Path "$DownloadPath\*.zip" -Force

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

$ProcessExitCode = RunProcess "$DownloadPath\Dreamweaver_x64\Build\Setup.exe" "--silent" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

$InstalledVersion = GetVersionFromRegistry "Adobe Dreamweaver"

# Get the Year version if it exists from the shortcut name
    $yearVersion = $null
    
    # Get the name of the shortcut without extension
    $shortcut = Get-ChildItem -Path "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs" -Filter "*Dreamweaver*.lnk" | Select-Object -First 1
    $shortcutName = [System.IO.Path]::GetFileNameWithoutExtension($shortcut.Name)
    
    # Get the last part of the split name
    $lastPart = ($shortcutName -split " ")[-1]   
    
    # Check if the last part matches the pattern #### (year number)
    if ($lastPart -match '^\d{4}$') {
        $yearVersion = $lastPart
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

# Publish again with the 4 digit year version
If ($yearVersion -ne $null) {
    PushImage $yearVersion
}