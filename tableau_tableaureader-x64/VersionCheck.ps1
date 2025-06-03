Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# We must pass these header values or the web request will get access denied
$headers = @{
    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "Accept-Encoding" = "gzip, deflate, br"
    "Accept-Language" = "en-US,en;q=0.9"
}

$response = Invoke-WebRequest -Uri "https://www.tableau.com/support/releases" -Headers $headers  -UseBasicParsing

$VersionLink = ($response.Links | Where-Object {$_.href -like "*desktop*"})[2].href
$LatestWebVersion = $VersionLink.Split("/")[-1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
