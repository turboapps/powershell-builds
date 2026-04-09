Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "Git-*-64-bit.exe" } | Select-Object -First 1
$LatestWebVersion = RemoveTrailingZeros ($asset.name -split '-')[1]

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
