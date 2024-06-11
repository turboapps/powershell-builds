Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = Invoke-WebRequest -Uri 'https://winscp.net/eng/downloads.php' -UseBasicParsing

# Get installer link with version number.
$VersionLink = ($Page.links | Where-Object {$_.href -like "*winscp-*.msi*"}).href

# Get version number.
$LatestWebVersion = (($VersionLink.split("/"))[-2] -replace "winscp-") -replace ".msi"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}