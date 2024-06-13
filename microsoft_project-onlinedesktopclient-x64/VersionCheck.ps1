Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://www.microsoft.com/en-us/download/details.aspx?id=49117' -UseBasicParsing

# Get installer link for latest version
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*download.microsoft.com*"})[0].href
$InstallerName = $DownloadLink.Split("/")[-1]

# Download the Office deployment tool
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
