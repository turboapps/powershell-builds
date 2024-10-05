Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Parse download page for latest version.
$Page = curl 'https://inkscape.org/release/' -UseBasicParsing
## match operator populates the $matches variable.
((($Page.Links | Where-Object {$_.outerhtml -like "*Current Stable Version*"})[0].outerhtml) -match '<span class="info">(.*)</span>')
$LatestWebVersion = $matches[1]

# Parse release page for installer filename, which includes a hashed suffix.
$Page2 = curl "https://inkscape.org/release/inkscape-$LatestWebVersion/windows/32-bit/msi/dl/" -UseBasicParsing
$InstallerName = ($Page2.Links.href -like "*.msi").split("/")[-1]

# Compute download link
# Example: https://media.inkscape.org/dl/resources/file/inkscape-1.3.2_2023-11-25_091e20ef0f-x86.msi
$DownloadLink = "https://media.inkscape.org/dl/resources/file/$InstallerName"

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
