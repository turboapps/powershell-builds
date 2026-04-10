Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$response = Invoke-WebRequest -Uri "https://winscp.net/eng/downloads.php" -UseBasicParsing
if ($response.Content -match 'WinSCP-([\d.]+)\.msi') {
    $LatestWebVersion = RemoveTrailingZeros $Matches[1]
} else {
    WriteLog "ERROR: Could not find WinSCP version on downloads page."
    exit 1
}

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
