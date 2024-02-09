Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get the version from the GitHub vector.control file
$Page = curl 'https://github.com/pgvector/pgvector/raw/master/vector.control' -UseBasicParsing

$Line =  $Page.Content -split "`n" | Where-Object { $_ -like '*default_version*' }
$LatestWebVersion = (($Line -split "=") -replace "'","")[1].Trim()

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
