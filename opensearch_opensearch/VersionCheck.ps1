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

# Get main download page for application.
$Page = curl https://opensearch.org/downloads.html -UseBasicParsing

# Get the latest tag for Compare-Versions
$VersionTag = (($Page.Links | Where-Object {$_.href -like "https://artifacts.opensearch.org/releases/bundle/opensearch/*windows-x64.zip"}).href).split("-")[1]
$LatestWebVersion = $VersionTag

# Remove trailing zeroes because Hub trims them, so need to match for Compare-Versions.
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}