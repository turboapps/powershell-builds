Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$html = curl.exe "https://www.tableau.com/support/releases"
$matches = Select-String -InputObject $html -Pattern '<a\s+(?:[^>]*?\s+)?href="([^"]*)"' -AllMatches
$links = $matches.Matches | ForEach-Object { $_.Groups[1].Value }
$VersionLink = ($links | Where-Object {$_ -like "*desktop*"})[2]

$LatestWebVersion = $VersionLink.Split("/")[-1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
