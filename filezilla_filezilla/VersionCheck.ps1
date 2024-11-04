Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use this section to get the latest version 
# either from the vendor website or the downloaded installer file

$url = "https://filezilla-project.org/download.php?show_all=1"
$page = EdgeGetContent -url $url -headlessMode "old"

# Define a regular expression pattern to match href links
$pattern = 'href\s*=\s*"(http[^"]*)"'
# Find all matches in the content
$matches = [regex]::Matches($page, $pattern)

# Extract the first link that contains "win32-setup" and display it
foreach ($match in $matches) {
    $DownloadLink = $match.Groups[1].Value
    if ($DownloadLink -like "*win32-setup*") {
        $DownloadLink = $DownloadLink -replace "amp;", ""
        break
    }
}


# Get the latest version tag.
$LatestWebVersion = $DownloadLink.split("_")[1]

# Remove trailing zeroes because Hub trims them, so need to match for Compare-Versions.
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}