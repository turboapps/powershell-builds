Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
# The content of this page is built by javascript so we need to use Edge in headless mode to get the content
$Page = EdgeGetContent https://github.com/NationalSecurityAgency/ghidra/releases/latest

# Split the content into lines
$PageLines = $Page -split "`n"

# Define a regular expression pattern
$InstallerNamePattern = '<a\s+href="(.*?ghidra.*?zip)".*?>'

# Filter and output lines containing matching links
foreach ($PageLine in $PageLines) {
    if ($PageLine -match $InstallerNamePattern) {
        $DownloadLink = "https://github.com" + $matches[1]  # Use the first link that matches the $InstallerNamePattern
        break
    }
}

$InstallerName = $DownloadLink.split("/")[-1]

$LatestWebVersion = $InstallerName.split("_")[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}