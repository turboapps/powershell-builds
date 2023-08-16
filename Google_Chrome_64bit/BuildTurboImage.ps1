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

$HubOrg = "google/chrome-x64"  # Set this for each package
$Vendor = "Google"
$AppDesc = "Free web browser developed by Google, enhanced for performance and privacy."
$AppName = "Chrome (64-bit)"
$VendorURL = "https://google.com/chrome"


##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Get installer link for latest version
$DownloadLink = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B2CC0992A-8A31-8D75-167C-5C46238DE706%7D%26lang%3Den%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEW/dl/chrome/install/googlechromestandaloneenterprise64.msi"
# Folder the installer will be downloaded to
$DownloadPath = New-Item -Path $scriptPath -Name "Installer" -ItemType "directory" -Force # create an Installer directory on the desktop for the donwnload
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
Copy-Item "$SupportFiles\initial_preferences" -Destination "C:\Program Files\Google\Chrome\Application\"  -Force
# Copy Google folder to localappdata - this folder contains files to prevent the Google Welcome page on first launch.
Copy-Item -Path "$SupportFiles\Google" -Destination "$env:LOCALAPPDATA\" -Recurse -Force

# Create "Chrome Apps" folder in Start Menu - creating this folder will prevent google app shortcuts from getting created
Copy-Item -Path "$SupportFiles\Chrome Apps" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\" -Recurse -Force

# Delete Google Update
&sc.exe stop gupdate
&sc.exe delete gupdate
&sc.exe stop gupdatem
&sc.exe delete gupdatem
&sc.exe stop GoogleChromeElevationService
&sc.exe delete GoogleChromeElevationService
Remove-Item -Path "C:\Program Files (x86)\Google\Update\*" -Recurse -Force

# Get the installed version from the registry
foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
    $name = (Get-ItemProperty $subkey.PSPath).DisplayName
    if ($name -eq "Google Chrome") {
        $InstalledVersion = (Get-ItemProperty $subkey.PSPath).DisplayVersion
    }
}
# Delete installer files
Remove-Item -Path "C:\Program Files\Google\Chrome\Application\$InstalledVersion\Installer\*" -Recurse -Force

# Uncomment this section to prevent the default browser prompt on first launch
# Add -no-default-browser-check argument to the Chrome shortcuts
<# $shortcutPath = "C:\Users\Public\Desktop\Google Chrome.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.Arguments = "-no-default-browser-check"
$shortcut.Save()
$shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.Arguments = "-no-default-browser-check"
$shortcut.Save() #>

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

