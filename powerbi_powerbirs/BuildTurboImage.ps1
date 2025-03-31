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
$AppDesc = "Power BI Report Server, available as part of Power BI Premium, enables on-premises web and mobile viewing of Power BI reports, plus the enterprise reporting capabilities of SQL Server Reporting Services."
$AppName = "PowerBI Desktop RS 64-bit"
$VendorURL = "https://powerbi.microsoft.com/en-us/desktop/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."


# Use the headless-extractor to get the download link
$url = "https://aka.ms/pbireportserver"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Define the path to the HTML file
$DOMFilePath = "$outputdir\dom.html"
$HtmlContent = Get-Content -Path $DOMFilePath -Raw

# Split the content into lines
$lines = $HtmlContent -split "`n"

# Use regex to match URLs that end with PBIDesktopSetupRS.exe
$regex = '(https://download.microsoft.com/download/[a-zA-Z0-9/-]+/PBIDesktopSetupRS_x64\.exe)'

# Find matches in the input string
$matches = [regex]::matches($lines, $regex)

$DownloadLink = $matches[0].Value

$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$InstalledVersion = Get-VersionFromExe "$Installer"
$InstalledVersion = RemoveTrailingZeros "$InstalledVersion"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

$ProcessExitCode = RunProcess "$DownloadPath\$InstallerName" "-q ACCEPT_EULA=1 DISABLE_UPDATE_NOTIFICATION=1 ENABLECXP=0" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Register .net registration-free COM objects 
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe" "C:\Program Files\Microsoft Power BI Desktop\bin\Microsoft.AnalysisServices.AzureClient.dll"
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe" "C:\Program Files\Microsoft Power BI Desktop\bin\Microsoft.AnalysisServices.DatasetSerializer.dll"
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe" "C:\Program Files\Microsoft Power BI Desktop\bin\Microsoft.AnalysisServices.MInterop.dll"

# This prevents a Get the most out of PowerBI dialog on second launch of PowerBI 
&reg.exe ADD "HKCU\SOFTWARE\Microsoft\Microsoft Power BI Desktop" /v ShowLeadGenDialog /t REG_DWORD /d 0 /f

# This prevents virtual spawned msedge.exe processes from staying running when Edge is closed and keeping the container running
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f

# Copy Power BI Desktop folder to localappdata - this folder contains files to enable Enhanced Sign In.
Copy-Item -Path "$SupportFiles\Power BI Desktop SSRS" -Destination "$env:LOCALAPPDATA\Microsoft" -Recurse -Force

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

