Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use this section to get the latest version 
# either from the vendor website or the downloaded installer file

# Get latest version from release notes page
$Page = curl 'https://product-details.mozilla.org/1.0/firefox_versions.json' -UseBasicParsing
$jsonData = $Page.Content | ConvertFrom-Json
$LatestWebVersion = $jsonData.LATEST_FIREFOX_VERSION
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}