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
$Page = curl 'https://www.mozilla.org/en-US/firefox/releases/' -UseBasicParsing
$VersionLink = ($Page.Links | Where-Object {$_.href -like "*/releasenotes/"})[1].href

# Use regular expression to extract the version number
$LatestWebVersion = [regex]::Match($VersionLink, '\d+(\.\d+)+').Value
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}