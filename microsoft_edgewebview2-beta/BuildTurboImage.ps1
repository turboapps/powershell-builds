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
$AppDesc = "WebView2 is a way for app developers to embed web content (such as HTML, JavaScript, and CSS) in Windows applications. This is the Beta channel runtime provided by Edge Beta."
$AppName = "Edge WebView2 Runtime Beta"
$VendorURL = "https://learn.microsoft.com/en-us/microsoft-edge/webview2/how-to/set-preview-channel"

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest MSI installer."

# There is no standalone WebView2 Beta runtime installer. The Beta WebView2 runtime is included in the Edge Beta install.
$edgeEnterpriseMSIUri = 'https://edgeupdates.microsoft.com/api/products?view=enterprise'
$Architecture = "x64"
$Platform = "Windows"
$channel = "Beta"

# Use the Edge Product release JSON page to get the latest version and download link
$response = Invoke-WebRequest -Uri $edgeEnterpriseMSIUri -Method Get -ContentType "application/json" -UseBasicParsing -ErrorVariable InvokeWebRequestError
$jsonObj = ConvertFrom-Json $([String]::new($response.Content))

$selectedIndex = [array]::indexof($jsonObj.Product, "$Channel")

$selectedVersion = (([Version[]](($jsonObj[$selectedIndex].Releases |
    Where-Object { $_.Architecture -eq $Architecture -and $_.Platform -eq $Platform }).ProductVersion) |
    Sort-Object -Descending)[0]).ToString(4)

$selectedObject = $jsonObj[$selectedIndex].Releases |
    Where-Object { $_.Architecture -eq $Architecture -and $_.Platform -eq $Platform -and $_.ProductVersion -eq $selectedVersion }
$LatestWebVersion = $selectedObject.ProductVersion
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

# Name of the downloaded installer file
$InstallerName = "MicrosoftEdgeBetaEnterpriseX64.msi"

# Get the download link for the latest version
foreach ($artifacts in $selectedObject.Artifacts) {
         $DownloadLink = $artifacts.Location
}

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

# Stop and delete all services matching the pattern "*edge*"
$pattern = "(?i)edge"
$services = Get-Service | Where-Object { $_.Name -match $pattern }

# Iterate through each service and stop it if it's running, then remove it
foreach ($service in $services) {
    if ($service.Status -eq "Running") {
        sc.exe stop $service.ServiceName
    }
    sc.exe delete $service.ServiceName
}

$InstalledVersion = GetVersionFromRegistry "Microsoft Edge Beta"

# Make WebView2 apps load the Beta channel runtime instead of the Stable WebView2 Runtime.
# The wildcard (*) applies the policy to all WebView2 apps running in the container.
# ChannelSearchKind 1 = search least stable channel first. ReleaseChannels "1" = only consider the Beta channel.
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge\WebView2\ChannelSearchKind" /v "*" /t REG_DWORD /d 1 /f
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge\WebView2\ReleaseChannels" /v "*" /t REG_SZ /d "1" /f

# This prevents virtual spawned msedge.exe processes from staying running and keeping the container running
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f
&reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f

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
