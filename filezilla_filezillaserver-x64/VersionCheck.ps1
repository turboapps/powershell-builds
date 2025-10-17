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
# Use the headless-extractor to get the download link
$url = "https://filezilla-project.org/download.php?type=server"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome-x64 --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

# Define a regular expression pattern
$pattern = 'win64-setup.exe'

# Filter and output lines containing matching links
foreach ($line in $links) {
    if ($line -match $pattern) {
        $DownloadLink = $line  # Directly use the matching URL
        $DownloadLink = $DownloadLink -replace "amp;", ""
        break
    }
}

$DownloadLink

# Get the latest version tag.
$LatestWebVersion = $DownloadLink.split("_")[2]

# Remove trailing zeroes because Hub trims them, so need to match for Compare-Versions.
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}