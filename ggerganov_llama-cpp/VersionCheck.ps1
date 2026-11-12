Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get latest version tag from repo
# Since 2026-11 llama.cpp marks its bNNNNN builds as prereleases, and releases/latest
# points at a vX.Y.Z tag with no Windows binaries. Take the newest bNNNNN tag instead.
$URL = "https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=30"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing
$latest = (ConvertFrom-Json $response.Content) | ForEach-Object { $_.tag_name } | Where-Object { $_ -match '^b\d+$' } | Select-Object -First 1
if (-not $latest) { throw "No bNNNNN release tag found at $URL" }

$LatestWebVersion = $latest.Substring(1) + ".0"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}