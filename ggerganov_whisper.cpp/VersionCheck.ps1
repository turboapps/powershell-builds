Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get latest version tag from repo
$URL = "https://api.github.com/repos/ggerganov/whisper.cpp/releases/latest"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = (ConvertFrom-Json $response.Content).tag_name
$latest -match "v(\d.\d.\d)"

$LatestWebVersion = $matches[1]

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}