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
$Vendor = "Dymo"
$AppDesc = "Supports all LabelWriter® 5 series, 450 series, 4XL, and LabelManager® 280, 420P and 500TS®."
$AppName = "Dymo Connect"
$VendorURL = "https://www.dymo.com/"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest installer."

# The content of this page is built by javascript so we need to use Edge in headless mode to get the content
$url = "https://www.dymo.com/support?cfid=user-guide"
$Page = EdgeGetContent -url $url -headlessMode "old"

# Split the content into lines
$lines = $Page -split "`n"
#$lines | Out-File -FilePath "$env:TEMP\dymopage.txt" -Append

# Define a regular expression pattern
$pattern = 'href="([^"]+\.exe)"'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $DownloadLink = $matches[1]  # Use the first link that matches *.exe*
        $DownloadLink
        break
    }
}
$InstallerName = $DownloadLink.split("/")[-1]
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

# Install the application silently using cmd to run the installer otherwise the /D param doesn't work
$ProcessExitCode = RunProcess $Installer "/S /v`"ALLUSERS=1 COLLECTDATA=0 /qn`"" $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Clean up the extracted installer to reduce the final image size
Remove-Item -Path "$env:LOCALAPPDATA\Downloaded Installations" -Recurse -Force

## Launch Dymo Connect to generate the user.config settings file.  Then kill the process.
. "C:\Program Files (x86)\DYMO\DYMO Connect\DYMOConnect.exe"
Start-Sleep -Seconds 10
taskkill /f /im DYMOConnect.exe /t

## Disable update checks
## Open the user.config file as XML and add the node to disable auto update checks
# Get the user.config 
$userConfigFiles = Get-ChildItem -Path "$env:LOCALAPPDATA\DYMO" -Recurse -Filter "user.config" | Select -First 1

foreach ($file in $userConfigFiles) {
    try {
        # Load the XML content of the user.config file
        [xml]$xmlContent = Get-Content -Path $file.FullName

        # Find the <DYMO.Windows.DCDesktop.Properties.Settings> node
        $settingsNode = $xmlContent.configuration.userSettings."DYMO.Windows.DCDesktop.Properties.Settings"

        if ($settingsNode) {
            # Create a new <setting> node
            $newSetting = $xmlContent.CreateElement("setting")
            $newSetting.SetAttribute("name", "CheckForUpdates")
            $newSetting.SetAttribute("serializeAs", "String")
            
            $valueElement = $xmlContent.CreateElement("value")
            $valueElement.InnerText = "False"

            $newSetting.AppendChild($valueElement) | Out-Null
            $settingsNode.AppendChild($newSetting) | Out-Null

            # Save the modified XML content back to the file
            $xmlContent.Save($file.FullName)
            
            Write-Output "Updated: $($file.FullName)"
        } else {
            Write-Output "Settings node not found in: $($file.FullName)"
        }
    } catch {
        Write-Output "Failed to process: $($file.FullName)"
        Write-Output $_.Exception.Message
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

########################
## Push Turbo Image   ##
########################

PushImage $InstalledVersion
