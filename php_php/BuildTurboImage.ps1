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
$Vendor = "The PHP Group"
$AppDesc = "A popular general-purpose scripting language that is especially suited to web development. 64-bit Non Thread Safe build."
$AppName = "PHP"
$VendorURL = "https://www.php.net/"

# php.net publishes the Windows binaries as a .zip, so this build extracts rather than installs.
$VcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"  # VC++ 2015-2022 runtime the vs16/vs17 builds link against
$PhpRoot     = "C:\php"                                          # install target

########################################
## Compare Hub Version to Web Version ##
########################################
CheckHubVersion

##########################################
## Download latest version of installer ##
##########################################
WriteLog "Downloading the latest .ZIP."

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# downloads.php defaults to Linux instructions, so ask for the Windows ZIP list explicitly. The
# default version shows only the current release branch.
$PhpDownloadPage = "https://www.php.net/downloads.php?os=windows&osvariant=windows-downloads&version=default"
$Page = Invoke-WebRequest -Uri $PhpDownloadPage -UseBasicParsing

# Zips live at downloads.php.net/~windows/releases/archives/php-<version>-nts-Win32-vs<nn>-x64.zip.
# The debug and devel packs share the suffix but are prefixed php-debug-pack- / php-devel-pack-, so
# requiring the version straight after "php-" skips them. The vs number changes with each toolchain
# bump, so match any.
$PhpMatch = [regex]::Match($Page.Content, 'href="(?<url>https://[^"]+/php-(?<ver>\d+(?:\.\d+)+)-nts-Win32-vs\d+-x64\.zip)"', 'IgnoreCase')
if (-not $PhpMatch.Success) {
    WriteLog "Could not find an x64 NTS .zip link on $PhpDownloadPage. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}

# Get installer link for latest version
$DownloadLink = $PhpMatch.Groups['url'].Value
WriteLog "Latest PHP x64 NTS build: $($PhpMatch.Groups['ver'].Value)"

# Name of the downloaded installer file
$InstallerName = [System.IO.Path]::GetFileName($DownloadLink)

# Download the install file
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# The PHP Windows builds do not ship the C runtime - the downloads page requires the Visual C++
# Redistributable for Visual Studio 2015-2022. Baking it into the image keeps the container self contained.
$VcRedist = DownloadInstaller $VcRedistUrl $DownloadPath "vc_redist.x64.exe"

#########################
## Start Turbo Capture ##
#########################

StartTurboCapture

#############################
## Install the application ##
#############################
WriteLog "Installing the application."

# Install the VC++ runtime that the PHP binaries link against.
# 1638 = a newer runtime is already present, 3010 = success but a reboot is pending. Neither is fatal.
$ProcessExitCode = RunProcess $VcRedist "/install /quiet /norestart" $True
if ($ProcessExitCode -eq 1638 -or $ProcessExitCode -eq 3010) {
    WriteLog "VC++ redistributable returned $ProcessExitCode - runtime already present or reboot pending. Continuing."
} else {
    CheckForError "Checking VC++ redistributable exit code:" 0 $ProcessExitCode $True # Fail on runtime install error
}

# The .zip has php.exe and friends at its root, so it expands straight into the install folder.
# Clear any existing copy first so files from an older version do not linger in the image.
if (Test-Path -Path $PhpRoot) {
    WriteLog "Removing existing $PhpRoot"
    Remove-Item -Path $PhpRoot -Recurse -Force
}
Expand-Archive -LiteralPath $Installer -DestinationPath $PhpRoot -Force

# Confirm the payload actually landed rather than letting the capture carry on and produce an
# image with no PHP in it.
if (-not (Test-Path -Path "$PhpRoot\php.exe")) {
    WriteLog "Expected $PhpRoot\php.exe after extraction but it is missing. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}
WriteLog "Extracted PHP to $PhpRoot"

################################
## Customize the application  ##
################################
WriteLog "Performing post-install customizations."

# Start from the production defaults that ship in the .zip.
$PhpIni = "$PhpRoot\php.ini"
WriteLog "Creating $PhpIni from php.ini-production"
$IniText = Get-Content -Path "$PhpRoot\php.ini-production" -Raw

# Point extension_dir at the absolute ext path. The commented default of "ext" is resolved against
# the current directory on Windows, so it breaks as soon as php is run from anywhere else.
$IniText = $IniText -replace '(?m)^;\s*extension_dir\s*=\s*"ext"', ('extension_dir = "' + "$PhpRoot\ext" + '"')

# Enable a common set of extensions by uncommenting their stock extension= lines. Every one of these
# needs only DLLs that ship in the .zip.
$PhpExtensions = @("curl", "exif", "fileinfo", "gd", "intl", "mbstring", "mysqli", "openssl", "pdo_mysql", "pdo_sqlite", "sodium", "sqlite3", "zip")
foreach ($Ext in $PhpExtensions) {
    # Match up to the line end without consuming the \r so the CRLF line endings survive.
    $ExtPattern = "(?m)^;(extension=$Ext)(?=\r?$)"
    if ($IniText -match $ExtPattern) {
        $IniText = $IniText -replace $ExtPattern, '$1'
    } else {
        WriteLog "No commented extension=$Ext line in php.ini-production - appending it."
        $IniText += "`r`nextension=$Ext"
    }
}

# Write without a BOM - PHP reads a BOM as output and emits it before every script.
[System.IO.File]::WriteAllText($PhpIni, $IniText, (New-Object System.Text.UTF8Encoding($false)))

# Confirm every extension actually loads. php prints a startup warning rather than failing when an
# extension is missing, so check the module list instead of the exit code.
$LoadedModules = & "$PhpRoot\php.exe" -c $PhpIni -m 2>&1 | ForEach-Object { "$_".Trim() }
$MissingModules = $PhpExtensions | Where-Object { $LoadedModules -notcontains $_ }
if ($MissingModules) {
    WriteLog "PHP failed to load extension(s): $($MissingModules -join ', '). Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}
WriteLog "Enabled PHP extensions: $($PhpExtensions -join ', ')"

# Set the $InstalledVersion variable to the latest version - must be set for the metadata
$InstalledVersion = RemoveTrailingZeros (Get-VersionFromExe "$PhpRoot\php.exe")

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
