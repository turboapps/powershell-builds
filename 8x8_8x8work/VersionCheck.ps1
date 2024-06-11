Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
# The content of this page is built by javascript so we need to use Edge in headless mode to get the content
$Page = EdgeGetContent 'https://support.8x8.com/business-phone/voice/work-desktop/download-8x8-work-for-desktop'

# Split the content into lines
$lines = $Page -split "`n"

# Define a regular expression pattern
$pattern = '<a\s+href="(.*?work-64-msi.*?)".*?>'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $DownloadLink = $matches[1]  # Use the first link that matches *work-64-msi*
        break
    }
}
$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}