Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get installer link for latest version
$Page = curl 'https://www.7-zip.org/download.html' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*.msi"})[0].href
$DownloadLink = "https://www.7-zip.org/" + $LatestInstaller
$InstallerName = $LatestInstaller.Split("/")[1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
