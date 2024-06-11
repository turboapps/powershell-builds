Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$URL = "https://dlcdn.apache.org/netbeans/netbeans-installers/"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$Page = $response.Links.Href[-1]

$LatestWebVersion = $Page.Split("/")[0]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}