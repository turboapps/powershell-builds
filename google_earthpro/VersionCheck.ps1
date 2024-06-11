Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = curl 'https://support.google.com/earth/answer/168344#zippy=%2Cdownload-a-google-earth-pro-direct-installer' -UseBasicParsing

# Get download page for latest version.
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*x64.exe"}).href[0]

# Name of the downloaded installer file
$InstallerName = $DownloadLink.split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Get the latest version tag.
$LatestWebVersion = $InstallerName.split("-")[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}