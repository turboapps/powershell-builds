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

# Same selection as BuildTurboImage.ps1: newest LTS major that has windows/aarch64
# binaries (not every LTS gets them -- see comment there).
$Platform = 'windows'
$Type = 'jdk'
$Arch = 'aarch64'
$ReleaseInfo = $null
foreach ($candidateMajor in ($jsonData.available_lts_releases | Sort-Object -Descending)) {
    $Assets = Invoke-WebRequest -Uri "https://api.adoptium.net/v3/assets/latest/$candidateMajor/hotspot?architecture=$Arch&image_type=$Type&os=$Platform&vendor=eclipse" -UseBasicParsing | ConvertFrom-Json
    if ($Assets) {
        $ReleaseInfo = $Assets
        break
    }
}
if (-not $ReleaseInfo) {
    WriteLog "No LTS major has windows/$Arch Temurin binaries. Exiting."
    WriteLog "BuildResult=failed"
    Exit 0
}

# Get the version from the Release json
$majorVer = $ReleaseInfo.version.major
$minorVer = $ReleaseInfo.version.minor
$buildVer = $ReleaseInfo.version.build
$LatestWebVersion = "$majorVer.$minorVer.$buildVer"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}