Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Parse download page for latest version.
$Page = curl 'https://www.irfanview.com/' -UseBasicParsing
## match operator populates the $matches variable.
$Page -match "Version (.*)</span>"
$LatestWebVersion = $matches[1]

# Parse download page for installer name.
$Page -match "https://.*(iview.*_plugins_setup.exe)"
$InstallerName = $matches[1]

# Parse download page for download link. 
# Main page lists FossHub, which does not allow direct download links. Build the Techspot download link instead.
# $Page -match "(https://.*iview.*_plugins_setup.exe)"
# $DownloadLink = $matches[1]
$DownloadLink = "https://files02.tchspt.com/down/$InstallerName"

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
