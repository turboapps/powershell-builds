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
$Vendor = "Apache Software Foundation"
$AppDesc = "The Apache HTTP Server, a secure, efficient and extensible HTTP/1.1 and HTTP/2 web server. 32-bit Apache Lounge build."
$AppName = "Apache HTTP Server x86"
$VendorURL = "https://httpd.apache.org/"

# Apache Lounge publishes the Windows binaries as a .zip, so this build extracts rather than installs.
$ALArch      = "win32"                                  # architecture token in the .zip file name
$VcRedistUrl = "https://aka.ms/vc14/vc_redist.x86.exe"  # runtime the VS18 binaries link against
$ServerRoot  = "C:\Apache24"                            # install target, and SRVROOT / ServerRoot in httpd.conf

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest .ZIP."

# apachelounge.com rejects the default PowerShell user agent with a protocol error, so send a
# browser one on every Invoke-WebRequest - including the wget alias inside DownloadInstaller.
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$ALDownloadPage = "https://www.apachelounge.com/download/"
$Page = Invoke-WebRequest -Uri $ALDownloadPage -UseBasicParsing

# Binaries live at /download/VS<nn>/binaries/httpd-<version>-<build>-<arch>-VS<nn>.zip. The arch
# token case is inconsistent on the page (Win64 vs win32) and the VS number changes with each
# toolchain bump, so scrape the href case-insensitively instead of building the URL by hand.
$ALMatch = [regex]::Match($Page.Content, "href=`"(?<url>/download/VS\d+/binaries/httpd-(?<ver>\d+(?:\.\d+)+)-(?<build>\d+)-$ALArch-VS\d+\.zip)`"", 'IgnoreCase')
if (-not $ALMatch.Success) {
    WriteLog "Could not find an $ALArch httpd .zip link on $ALDownloadPage. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}

# Get installer link for latest version
$DownloadLink = "https://www.apachelounge.com" + $ALMatch.Groups['url'].Value
WriteLog "Latest Apache Lounge $ALArch build: $($ALMatch.Groups['ver'].Value)-$($ALMatch.Groups['build'].Value)"

# Name of the downloaded installer file
$InstallerName = [System.IO.Path]::GetFileName($DownloadLink)

# Download the install file
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Apache Lounge does not ship the C runtime with the binaries - see ReadMe.txt in the .zip, which
# requires the Visual C++ Redistributable for Visual Studio 2017-2026. Baking it into the image
# keeps the container self contained. To layer it from the hub instead, drop this download and the
# RunProcess call below and uncomment the AddDependency line in PostCaptureModifications.ps1.
$VcRedist = DownloadInstaller $VcRedistUrl $DownloadPath "vc_redist.x86.exe"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the VC++ runtime that the VS18 binaries link against.
# 1638 = a newer runtime is already present, 3010 = success but a reboot is pending. Neither is fatal.
$ProcessExitCode = RunProcess $VcRedist "/install /quiet /norestart" $True
if ($ProcessExitCode -eq 1638 -or $ProcessExitCode -eq 3010) {
    WriteLog "VC++ redistributable returned $ProcessExitCode - runtime already present or reboot pending. Continuing."
} else {
    CheckForError "Checking VC++ redistributable exit code:" 0 $ProcessExitCode $True # Fail on runtime install error
}

# The .zip root holds Apache24 plus an architecture marker file, a ReadMe and - on the win32 build -
# a stray copy of the Win64 .zip. Expand to a staging folder and move only Apache24 into place so
# that none of that ends up in the image.
$Staging = "$env:TEMP\ApacheLoungeStaging"
if (Test-Path -Path $Staging) { Remove-Item -Path $Staging -Recurse -Force }
Expand-Archive -LiteralPath $Installer -DestinationPath $Staging -Force
# C:\Apache24 is the path the Apache Lounge ReadMe documents, so it may already exist on a re-run
# or a dirty VM. Clear it first - Move-Item would otherwise nest the payload inside it.
if (Test-Path -Path $ServerRoot) {
    WriteLog "Removing existing $ServerRoot"
    Remove-Item -Path $ServerRoot -Recurse -Force
}
Move-Item -LiteralPath "$Staging\Apache24" -Destination $ServerRoot -Force
Remove-Item -Path $Staging -Recurse -Force

# Move-Item raises a non-terminating error, so confirm the payload actually landed rather than
# letting the capture carry on and produce an image with no Apache in it.
if (-not (Test-Path -Path "$ServerRoot\bin\httpd.exe")) {
    WriteLog "Expected $ServerRoot\bin\httpd.exe after extraction but it is missing. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}
WriteLog "Extracted Apache to $ServerRoot"

# The win32 .zip ships the Win64 build nested inside it, so confirm the payload really is 32-bit
# rather than silently publishing x64 binaries under the x86 repo name.
$PeBytes = [System.IO.File]::ReadAllBytes("$ServerRoot\bin\httpd.exe")
$PeOffset = [System.BitConverter]::ToInt32($PeBytes, 0x3C)
$Machine = [System.BitConverter]::ToUInt16($PeBytes, $PeOffset + 4)
if ($Machine -ne 0x014C) {
    WriteLog ("httpd.exe is not a 32-bit image (PE machine type 0x{0:X4}, expected 0x014C). Exiting." -f $Machine)
    WriteLog "BuildResult=Failed"
    Exit 1
}
WriteLog "Verified httpd.exe is a 32-bit (i386) image."

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# The stock config hardcodes the server root as C:/Apache24, which is where this build installs, so
# this normally rewrites the Define to the value it already has. It is kept so that SRVROOT always
# tracks $ServerRoot - change the install path above and the config follows without further edits.
# Everything else in conf resolves through ${SRVROOT}, so this one Define is the only path involved.
# conf\original is Apache's pristine copy of the same file - keep the two in sync.
foreach ($Conf in @("$ServerRoot\conf\httpd.conf", "$ServerRoot\conf\original\httpd.conf")) {
    if (Test-Path -Path $Conf) {
        WriteLog "Setting SRVROOT to $ServerRoot in $Conf"
        $ConfText = Get-Content -Path $Conf -Raw
        $ConfText = $ConfText -replace '(?m)^(\s*Define\s+SRVROOT\s+)"[^"]*"', ('$1"' + $ServerRoot.Replace('\', '/') + '"')
        # Write without a BOM and without adding a trailing newline - httpd will not parse a BOM.
        [System.IO.File]::WriteAllText($Conf, $ConfText, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# Set the $InstalledVersion variable to the latest version - must be set for the metadata
$InstalledVersion = RemoveTrailingZeros (Get-VersionFromExe "$ServerRoot\bin\httpd.exe")

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
