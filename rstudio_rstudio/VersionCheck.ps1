Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$URL = 'https://posit.co/download/rstudio-desktop/'

# Get main download page for application.
$Page = curl $URL -UseBasicParsing

$DownloadLink = $Page.Links | Where-Object { $_.href -like '*windows/rstudio*' } | Select-Object -ExpandProperty href -First 1

$InstallerName = Split-Path -Path $DownloadLink -Leaf

$LatestWebVersion = ($InstallerName  -split '-')[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}