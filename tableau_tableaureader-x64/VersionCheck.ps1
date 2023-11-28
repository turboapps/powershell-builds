Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$URL = "https://www.tableau.com/support/releases"

$Page = curl $URL -UseBasicParsing
$VersionLink = ($Page.Links | Where-Object {$_.href -like "*desktop*"})[2].href

$LatestWebVersion = $VersionLink.Split("/")[-1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

Write-Log "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}