Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the headless-extractor to get the download link
$url = "https://winscp.net/eng/downloads.php"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Define the path to the HTML file
$DOMFilePath = "$outputdir\dom.html"
$HtmlContent = Get-Content -Path $DOMFilePath -Raw

# Split the content into lines
$lines = $HtmlContent -split "`n"

# Define a regular expression pattern
$pattern = 'WinSCP-[\d\.]+\.msi'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $InstallerName = $matches[0]  # Use the first link that matches
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
