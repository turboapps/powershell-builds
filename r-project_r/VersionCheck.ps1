Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$URL = 'https://cran.rstudio.com/bin/windows/base/'

# Get main download page for application.
$Page = curl $URL -UseBasicParsing

$InstallerName = $Page.Links | Where-Object { $_.href -like '*win.exe*' } | Select-Object -ExpandProperty href

$LatestWebVersion = ($InstallerName  -split '-')[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}