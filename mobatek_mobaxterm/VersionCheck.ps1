Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get installer link for latest version
$Page = curl 'https://mobaxterm.mobatek.net/download-home-edition.html' -UseBasicParsing

# Get installer link for latest version
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*installer*"})[0].href
Write-Host $DownloadLink

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]
Write-Host $InstallerName

# Use regex to capture the version after '_v'
if ($InstallerName -match "_v([0-9]+(?:\.[0-9]+)*)") {
    $LatestWebVersion = $matches[1]
    Write-Output $LatestWebVersion
}

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
