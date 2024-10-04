Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://download.documentfoundation.org/libreoffice/stable/' -UseBasicParsing

$versionRegex = [regex]'\d+\.\d+\.\d+'
$versionMatches = $versionRegex.Matches($Page.Content)

# Get the last version from the matches
$LatestWebVersion = $versionMatches[$versionMatches.Count - 1].Value

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}