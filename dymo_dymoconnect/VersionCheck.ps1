Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$versions = Invoke-RestMethod "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/d/DYMO/DYMOConnect"
$latestVersion = ($versions | Sort-Object { [version]$_.name } -Descending | Select-Object -First 1).name

if (-not $latestVersion) {
    WriteLog "ERROR: Could not find DYMO Connect version in winget-pkgs."
    exit 1
}
$LatestWebVersion = RemoveTrailingZeros $latestVersion

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
