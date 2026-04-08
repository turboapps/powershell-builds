Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$release = Invoke-RestMethod "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows&num=1"
$LatestWebVersion = RemoveTrailingZeros $release[0].version

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}