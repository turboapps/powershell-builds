Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = EdgeGetContent -url 'https://winscp.net/eng/downloads.php' -headlessMode "old"
# Split the content into lines
$lines = $Page -split "`n"

# Define a regular expression pattern
$pattern = 'WinSCP-[\d\.]+\.msi'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $InstallerName = $matches[0]  # Use the first link that matches *.exe*
        break
    }
}

# Get version number.
$LatestWebVersion = ($InstallerName -replace "winscp-") -replace ".msi"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
