Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Download the latest installer
$DownloadLink = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=249551_4d245f941845490c91360409ecffb3b4"
$InstallerName = "jre-windows-x64.exe"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Get the version from the downloaded installer file
Get-VersionFromExe $Installer

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"
# Remove any middle .0 from the version
$LatestWebVersion = $LatestWebVersion -replace '\.0\.', '.'

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}