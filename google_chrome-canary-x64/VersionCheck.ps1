Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get latest version from the Google APIs
$Page = curl 'https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/canary/versions?order_by=version%20desc&page_size=1' -UseBasicParsing
$jsonData = $Page.Content | ConvertFrom-Json
$LatestWebVersion = $jsonData.versions.version
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}