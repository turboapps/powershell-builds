Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Define the URL
$url = "https://github.com/Hibbiki/chromium-win64/releases/latest"

# Fetch the HTML content of the page
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$htmlContent = $response.Content

# Use regex to find version tags
$regex = 'tag\/([^"\/]+)"'
$matches = [regex]::Matches($htmlContent, $regex)

# Collect the first matched version tag
$versionTag = $matches[1].Groups[1].Value
$version = $versionTag -replace '^v', '' -replace '-r\d+$', ''

$LatestWebVersion = RemoveTrailingZeros "$version"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}