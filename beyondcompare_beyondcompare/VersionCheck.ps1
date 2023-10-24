Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get installer link for latest version
$Page = curl 'https://www.scootersoftware.com/kb/dl4_winalternate' -UseBasicParsing

# Get installer link for latest version
$LatestInstaller = ($Page.Links | Where-Object {$_.href -like "*_x64.msi"}).href
$DownloadLink = "https://www.scootersoftware.com" + $LatestInstaller
$InstallerName = $LatestInstaller.Split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
