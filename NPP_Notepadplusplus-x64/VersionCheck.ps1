Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = Invoke-WebRequest -Uri 'https://notepad-plus-plus.org/downloads/' -UseBasicParsing
# Get download page for latest version.
$Page2 = Invoke-WebRequest -Uri ('https://notepad-plus-plus.org' + ($Page.Links | Where-Object {$_.outerHTML -like "*Current Version*"}).href) -UseBasicParsing

# Assuming the VersionLink is /downloads/v##.##.##/ we will split out the version and remove the "v" to get only the version part of the link
$VersionLink = ($Page2.Links | Where-Object {$_.href -like "*downloads*"})[0]
$LatestWebVersion = $VersionLink.href.Split("/")[2] -replace "v"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}