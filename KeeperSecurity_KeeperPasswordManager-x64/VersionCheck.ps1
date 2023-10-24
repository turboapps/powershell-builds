Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$page = curl "https://docs.keeper.io/release-notes/desktop/web-vault-+-desktop-app" -UseBasicParsing

# Find all anchor elements ('a') in the HTML
$versionLink = ($Page.Links | Where-Object {$_.outerHTML -like "*vault release*"})[1].href

# Strip out the version from the link
$parts = $versionLink -split '-'
$LatestWebVersion = $parts[-1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}