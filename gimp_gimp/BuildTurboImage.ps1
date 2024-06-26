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
$Vendor = "Gimp"
$AppDesc = "GIMP is a freely distributed program for such tasks as photo retouching, image composition and image authoring."
$AppName = "Gimp"
$VendorURL = "https://www.gimp.org/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

$Page = curl 'https://www.gimp.org/downloads/' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*setup.exe"})[0].href

$DownloadLink = "https:" + $LatestInstaller

# Name of the downloaded installer file
$InstallerName = $LatestInstaller.Split("/")[-1]

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
$ProcessExitCode = RunProcess $Installer "/VERYSILENT /NORESTART /TYPE=`"FULL`" /MERGETASKS=`"desktopicon`" /ALLUSERS /NOCLOSEAPPLICATIONS /NOCANCEL /SUPPRESSMSGBOXES" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Disable update check
    # Get all the files named "gimprc" in the subfolders
    $files = Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "gimprc" -File

    foreach ($file in $files) {
        # Read the content of the file
        $content = Get-Content -Path $file.FullName

        # Replace the line if it matches "# (check-updates yes)"
        $updatedContent = $content -replace '# \(check-updates yes\)', '(check-updates no)'

        # Write the updated content back to the file
        Set-Content -Path $file.FullName -Value $updatedContent

        WriteLog "Updated file: $($file.FullName)"
    }

# Launch GIMP - this will speed up first launch of a new session
    # Define the path to the Start Menu Programs directory for all users
    $startMenuPath = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs"

    # Get all .lnk files in the Start Menu Programs directory and subdirectories
    $shortcutFiles = Get-ChildItem -Path $startMenuPath -Filter *.lnk -Recurse

    # Find the .lnk file that contains "GIMP" in its name
    $gimpShortcut = $shortcutFiles | Where-Object { $_.Name -like "*GIMP*" }

    # Check if the GIMP shortcut was found
    if ($gimpShortcut) {
        # Get the full path to the GIMP shortcut
        $gimpShortcutPath = $gimpShortcut.FullName

        # Use the Shell COM object to resolve the target path of the .lnk file
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($gimpShortcutPath)
        $targetPath = $shortcut.TargetPath

        # Launch the target application
        Start-Process -FilePath $targetPath
    } else {
        WriteLog "GIMP shortcut not found."
    }

Start-Sleep -Seconds 90

#########################
## Stop Turbo Capture  ##
#########################

StopTurboCapture

######################
## Customize XAPPL  ##
######################

CustomizeTurboXappl "$SupportFiles\PostCaptureModifications.ps1"  # Helper script for XML changes to Xappl"

# Set the plugin exes to precachable="False" - this is a workaround to prevent the plugins from being reloaded on first launch of a new session - APPQ-3781
# Read the contents of the file
$fileContent = Get-Content -Path $FinalXapplPath

# Perform the first find and replace operation
$fileContent = $fileContent -replace 'precacheable="True" source="\.\\Files\\Default\\@PROGRAMFILES@\\GIMP 2\\lib\\gimp\\2.0\\plug-ins', 'precacheable="False" source=".\Files\Default\@PROGRAMFILES@\GIMP 2\lib\gimp\2.0\plug-ins'

# Save the updated content back to the file
Set-Content -Path $FinalXapplPath -Value $fileContent

WriteLog "Find and replace operations completed successfully."

#########################
## Build Turbo Image   ##
#########################

BuildTurboSvmImage

########################
## Push Turbo Image   ##
########################

PushImage $InstalledVersion
