Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get latest release version
$URL = "https://www.gyan.dev/ffmpeg/builds/release-version"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = [System.Text.Encoding]::UTF8.GetString($response.Content)

$LatestWebVersion = $latest

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}