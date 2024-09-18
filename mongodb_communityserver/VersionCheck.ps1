Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://www.mongodb.com/try/download/community' -UseBasicParsing

# Split the content into lines
$lines = $Page -split "`n"

# Use regex to match URLs that end with PBIDesktopSetupRS.exe
$regex = 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-[\d\.]+-signed\.msi'

# Find matches in the input string
$matches = [regex]::matches($lines, $regex)

$DownloadLink = $matches[0].Value

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]

# Get the version
$LatestWebVersion = $InstallerName.Split("-")[3]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
