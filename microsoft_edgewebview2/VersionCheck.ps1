Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://www.catalog.update.microsoft.com/Search.aspx?q=Microsoft%20Edge%20WebView2%20Runtime' -UseBasicParsing

# Get installer link for latest version
$Links = ($Page.Links | Where-Object {$_.href -like "javascript:void(0);"})[2].outerHTML
$LatestWebVersion = $Links -match 'Build (\d+(\.\d+)*)'
$LatestWebVersion = $matches[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
