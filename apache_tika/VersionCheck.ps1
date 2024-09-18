Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application
$URL = "https://tika.apache.org/download.html"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = ($response.Links | Where-Object href -like '*tika-app*.jar').href
$regex = '(?<tag>\d+\.\d+\.\d+)\.jar'
foreach ($link in $latest)
{
    # Get the latest stable release
    if ($link -match $regex)
    {
        break
    }
}

$LatestWebVersion = $matches.tag

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}