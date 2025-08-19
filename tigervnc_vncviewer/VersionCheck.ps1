Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://github.com/TigerVNC/tigervnc/releases' -UseBasicParsing

# Get installer link for latest version
$LatestInstallerLink = ($Page.Links | Where-Object {$_.href -like "*stable*"})[0].href
WriteLog $LatestInstallerLink

$LatestWebVersion = $LatestInstallerLink.Split("/")[-1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
