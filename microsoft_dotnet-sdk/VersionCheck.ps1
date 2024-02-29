Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Add code here to get the latest version available

$Page = curl 'https://versionsof.net/core/' -UseBasicParsing

$LatestWebVersion = (($Page.Links | Where-Object {$_.href -like "*core*"})[2])
$LatestWebVersion = ($LatestWebVersion -split '<a.*?>|</a>')[1]

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
