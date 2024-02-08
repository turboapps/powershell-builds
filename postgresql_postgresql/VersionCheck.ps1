Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = curl 'https://www.enterprisedb.com/downloads/postgres-postgresql-downloads' -UseBasicParsing

# Get installer link for latest version.
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*fileid*"})[1].href

$Installer = wget $DownloadLink -UseBasicParsing -O $DownloadPath
$InstallerName = "PostgresInstaller.exe"

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
