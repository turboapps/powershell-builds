Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# 32bit Adobe Reader version is typically one release back from the 64bit
# We need to get the second release version from the Release Notes page
$DownloadPath = "C:\Users\admin\Desktop\Package\Installer"
# Use the headless-extractor to get the HTML from the Releases page
$url = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Define the path to the HTML file
$DOMFilePath = "$outputdir\dom.html"

# Read the HTML file content
$HtmlContent = Get-Content -Path $DOMFilePath -Raw

# Extract hyperlinks and text using regex
$Matches = [regex]::Matches($HtmlContent, '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', 'IgnoreCase')

# Filter links containing "dccontinuous"
$FilteredLinks = @()
foreach ($Match in $Matches) {
    $Href = $Match.Groups[1].Value
    $Text = $Match.Groups[2].Value -replace '\s+', ' '  # Clean up whitespace

    if ($Href -match "#dccontinuous") {
        $FilteredLinks += [PSCustomObject]@{
            URL  = $Href
            Text = $Text
        }
    }
}

# Get the text from the second matching link
if ($FilteredLinks.Count -ge 2) {
    $SecondLinkText = $FilteredLinks[1].Text
    $SecondLinkText -match '\d+(\.\d+)+'
    $LatestWebVersion = $matches[0]
    WriteLog "Extracted Version: $LatestWebVersion"
} else {
    WriteLog "Less than two matching links found."
}

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}