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
$Vendor = "WinSCP"
$AppDesc = "WinSCP is a popular SFTP client and FTP client for Microsoft Windows!"
$AppName = "WinSCP"
$VendorURL = "https://winscp.net/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion
    
##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# Use the headless-extractor to get the download link
$url = "https://winscp.net/eng/downloads.php"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Define the path to the HTML file
$DOMFilePath = "$outputdir\dom.html"
$HtmlContent = Get-Content -Path $DOMFilePath -Raw

# Split the content into lines
$lines = $HtmlContent -split "`n"

# Define a regular expression pattern
$pattern = 'WinSCP-[\d\.]+\.msi'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $InstallerName = $matches[0]  # Use the first link that matches
        break
    }
}
$DownloadLink =  "https://winscp.net/download/$InstallerName/download"

pushd $DownloadPath
$Installer = . C:\Windows\System32\curl.exe -L -o $InstallerName $DownloadLink

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Instllation flags documented at https://winscp.net/eng/docs/guide_install, but we use the MSI installer
# /qn: silent install
# /norestart: don't reboot
$ProcessExitCode = RunProcess "msiexec.exe" "/I $DownloadPath\$InstallerName /qn /norestart" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Set version meta.
$InstalledVersion = ($InstallerName -replace "winscp-") -replace ".msi"

# Set autoupdate checks to never.
&reg add "HKEY_CURRENT_USER\SOFTWARE\Martin Prikryl\WinSCP 2\Configuration\Interface\Updates" /v Period /t REG_DWORD /d 0 /f
# Disable showing updates on launch.
&reg add "HKEY_CURRENT_USER\SOFTWARE\Martin Prikryl\WinSCP 2\Configuration\Interface\Updates" /v ShowOnStartup /t REG_DWORD /d 0 /f
# Disable checking for beta versions.
&reg add "HKEY_CURRENT_USER\SOFTWARE\Martin Prikryl\WinSCP 2\Configuration\Interface\Updates" /v BetaVersions /t REG_DWORD /d 1 /f
# Disable collection of statistics.
&reg add "HKEY_CURRENT_USER\SOFTWARE\Martin Prikryl\WinSCP 2\Configuration\Interface" /v CollectUsage /t REG_DWORD /d 0 /f



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

