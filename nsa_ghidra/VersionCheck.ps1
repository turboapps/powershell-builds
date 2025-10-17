Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################


# Use the headless-extractor to get the download link
$url = "https://github.com/NationalSecurityAgency/ghidra/releases/latest"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome-x64 --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Define the path to the HTML file
$DOMFilePath = "$outputdir\dom.html"
$HtmlContent = Get-Content -Path $DOMFilePath -Raw

# Split the content into lines
$PageLines = $HtmlContent -split "`n"

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