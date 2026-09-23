Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Platform = 'windows'
$Type = 'jre'

# List of feature releases, newest first
$releases = (Invoke-RestMethod -Uri "https://api.adoptium.net/v3/info/available_releases").available_lts_releases | Sort-Object -Descending

# The newest listed release may not have a GA build for this platform yet, so walk down until one does
$ReleaseInfo = $null
foreach ($major in $releases) {
    $ReleaseInfo = Invoke-RestMethod -Uri "https://api.adoptium.net/v3/assets/latest/$major/hotspot?architecture=x64&image_type=$Type&os=$Platform&vendor=eclipse" |
        Select-Object -First 1
    if ($ReleaseInfo) { break }
}
if (-not $ReleaseInfo) { throw "No $Type release found for $Platform x64" }

# Build the version string: major.minor.security (plus .patch when present, e.g. 26.0.2.1)
$v = $ReleaseInfo.version
$LatestWebVersion = "$($v.major).$($v.minor).$($v.security)"
if ($v.patch) { $LatestWebVersion += ".$($v.patch)" }

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}