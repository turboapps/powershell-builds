Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$URL = 'https://cran.r-project.org/bin/windows/Rtools/'

$Page = curl $URL -UseBasicParsing

$LatestVersionLink =  ($Page.Links | Where-Object {$_.outerHTML -like "*RTools*"}).href[0]
$LatestVersion = ($LatestVersionLink -Split '/')[0]

$Page2 = curl ($URL + $LatestVersionLink) -UseBasicParsing

$DownloadLink = $Page2.Links | Where-Object { $_.href -like '*.exe*' } | Select-Object -ExpandProperty href
$DownloadLink = $URL + $LatestVersion + "/" + $DownloadLink 

# Name of the downloaded installer file
$InstallerName = Split-Path -Path $DownloadLink -Leaf

$Installer = wget $DownloadLink -O $DownloadPath\$InstallerName

$LatestWebVersion = Get-VersionFromExe "$DownloadPath\$InstallerName"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}