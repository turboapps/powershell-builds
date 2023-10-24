Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

## Determine the latest version of installer
$url = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
$output = Start-Process -FilePath 'c:\windows\system32\curl.exe' -ArgumentList $url -Wait -RedirectStandardOutput "$ENV:Temp\WebContent.txt"
$webContent = Get-Content "$ENV:Temp\WebContent.txt"
$lines = $webContent.Split("`n")

# Look for the first instance of <link rel="next" in the source page
foreach ($line in $lines) {
    if ($line -match '<link rel="next"') {

        $output = $line 
        break
    }
}

# Use regular expression to match a sequence of digits separated by dots
$pattern = "\d+(?:\.\d+)*"
$matches = [regex]::Matches($output, $pattern)

# Extract the first match as the version text
$LatestWebVersion = $matches[0].Value
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}