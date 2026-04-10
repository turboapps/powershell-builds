Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$releases = Invoke-RestMethod "https://api.github.com/repos/HydrologicEngineeringCenter/hec-downloads/releases?per_page=20"
$asset = $releases | ForEach-Object { $_.assets } | Where-Object { $_.name -like "HEC-HMS_*_Setup.exe" } | Select-Object -First 1

if ($asset.name -notmatch 'HEC-HMS_(\d)(\d+)_Setup\.exe') {
    WriteLog "ERROR: Could not find HEC-HMS setup asset in recent GitHub releases."
    exit 1
}
$LatestWebVersion = RemoveTrailingZeros "$($Matches[1]).$($Matches[2])"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
