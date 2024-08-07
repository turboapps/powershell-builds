Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://trillian.im/get/windows/thanks/' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*windows*"})[0].href

$DownloadLink = "https://trillian.im/$LatestInstaller"

# Name of the downloaded installer file
$InstallerName = "trillian.exe"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
