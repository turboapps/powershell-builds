Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html' -UseBasicParsing

# Get installer link for latest version (wa64 = Windows on Arm 64-bit; *arm64* excludes the arm32 installer)
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*arm64*.msi"})[0].href

$InstallerName = $DownloadLink.Split("/")[-1]

$LatestWebVersion = $InstallerName.Split("-")[-2]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
