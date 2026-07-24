Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$releasesIndex = Invoke-RestMethod "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"
$latestStable = $releasesIndex.'releases-index' |
    Where-Object { $_.'support-phase' -eq 'active' } |
    Sort-Object { [version]$_.'channel-version' } -Descending |
    Select-Object -First 1
$LatestWebVersion = RemoveTrailingZeros $latestStable.'latest-release'

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
