Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get link for latest version
$Page = Invoke-WebRequest 'https://cygwin.com/index.html' -UseBasicParsing


# Use regex to find the first cygwin-announce link and capture the link text
if ($Page.Content -match '<a[^>]+href="[^"]*cygwin-announce[^"]*"[^>]*>\s*([^<]+)\s*</a>') {
    $LatestWebVersion = $matches[1]
}
$LatestWebVersion
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
