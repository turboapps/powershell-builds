Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get major version of the latest release
$url = "https://api.adoptium.net/v3/info/available_releases"
$response = curl -Uri $url -UseBasicParsing
$jsonData = $response.Content | ConvertFrom-Json
$latestMajorVersion = $jsonData.available_lts_releases[-1]

# Use the vendor API to get the latest release given the major version
$Platform = 'windows'
$Type = 'jre'
$ReleaseInfo = Invoke-WebRequest -Uri "https://api.adoptium.net/v3/assets/latest/$latestMajorVersion/hotspot?architecture=x64&image_type=$Type&os=$Platform&vendor=eclipse" -UseBasicParsing | ConvertFrom-Json

# Download the zip
$InstallerName = $ReleaseInfo.binary.package.name
$DownloadLink = "https://api.adoptium.net/v3/binary/latest/$latestMajorVersion/ga/$Platform/x64/$Type/hotspot/normal/eclipse"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = $InstallerName.Split("_")[-2]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}