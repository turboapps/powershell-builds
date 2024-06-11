Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl "https://github.com/microsoft/winget-cli/releases/latest" -UseBasicParsing

$LatestWebVersion = (($Page.Links | Where-Object {$_.href -like "*winget-cli/releases*"})[1].href).split("/")[-1] -replace '^v', ''

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}