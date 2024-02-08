Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Define the URL
$chromeVersionURL = "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions"

# Make a GET request
$response = Invoke-RestMethod -Uri $chromeVersionURL -UseBasicParsing

# Extract the latest version
$LatestWebVersion = $response.versions[0].version
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}