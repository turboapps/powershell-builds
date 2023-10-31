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
$Page = curl https://github.com/paintdotnet/release/releases/latest -UseBasicParsing

# Get the latest tag (used to build download link) and installed version (used to build download link and svm image meta).
$VersionTag = (($Page.Links | Where-Object {$_.href -like "*/releases/tag*"}).href).split("/")[-1]
$LatestWebVersion = $VersionTag.Substring(1)

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}