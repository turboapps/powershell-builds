Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$URL = 'https://www.python.org/downloads/windows/'
$Page = curl $URL -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*downloads/release*"})[0].href

$URL = 'https://www.python.org' + $LatestInstaller

$Page = curl $URL -UseBasicParsing
$DownloadLink = ($Page.Links | Where-Object {$_.outerHTML -like "*Windows installer*32*"})[0].href

$InstallerName = $DownloadLink.Split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = $InstallerName.Split("-")[1]
$LatestWebVersion = RemoveTrailingZeros $LatestWebVersion

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
