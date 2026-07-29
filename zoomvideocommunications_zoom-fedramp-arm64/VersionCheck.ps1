Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# The x64 variant scrapes zoomgov.com/download/admin via the turbo/headless-extractor
# image, but Turbo containers do not run on the Windows-on-ARM capture VMs. Use the
# direct latest-client endpoint instead and read the version from the MSI.
$DownloadLink = "https://zoomgov.com/client/latest/ZoomInstallerFull.msi?archType=winarm64"

# Name of the downloaded installer file
$InstallerName = "ZoomInstallerFull.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
