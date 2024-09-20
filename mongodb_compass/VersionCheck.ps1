Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$Page = curl 'https://www.mongodb.com/try/download/compass' -UseBasicParsing

# Split the content into lines
$lines = $Page -split "`n"

# Use regex to match URLs that end with PBIDesktopSetupRS.exe
$regex = 'https://downloads.mongodb.com/compass/mongodb-compass-[\d\.]+-win32-x64\.msi'

# Find matches in the input string
$matches = [regex]::matches($lines, $regex)

$DownloadLink = $matches[0].Value

# Name of the downloaded installer file
$InstallerName = $DownloadLink.Split("/")[-1]

# Get the version
$LatestWebVersion = $InstallerName.Split("-")[2]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
