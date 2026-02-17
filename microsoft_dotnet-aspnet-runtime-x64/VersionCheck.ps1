Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$URL = "https://versionsof.net/core/"
$Page = Invoke-WebRequest $URL -UseBasicParsing

$MajorVersions = (($Page.Links | Where-Object {$_.href -match '^/core/\d+\.\d+/$'} | Select-Object -Skip 1))

ForEach ($MajorVersion in $MajorVersions) {
 # Find the first link that doesn't have "preview"
    if ($MajorVersion -notmatch '(?i)preview') {
        $LatestStableVersion = ($MajorVersion -split '<a.*?>|</a>')[1]
        Break
    }
}

Write-Host "Latest Stable Version: $LatestStableVersion"

$URL = "https://versionsof.net/core/$LatestStableVersion"
$Page1 = Invoke-WebRequest $URL -UseBasicParsing
$LatestWebVersion = (($Page1.Links | Where-Object {$_.outerHTML -match '>(\d+(\.\d+)*)<'})[1])
$LatestWebVersion = ($LatestWebVersion -split '<a.*?>|</a>')[0]

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
