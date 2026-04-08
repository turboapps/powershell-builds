Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the headless-extractor to get the download link
$url = "https://www.dymo.com/support?cfid=user-guide"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome-x64 --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

# Filter links for the x64 Windows installer
foreach ($line in $links) {
    if ($line -match 'DCDWIN.*X64.*\.exe') {
        $DownloadLink = $line
        break
    }
}

if (-not $DownloadLink) {
    WriteLog "ERROR: No DYMO installer link found. Check if the download page structure changed."
    exit 1
}

# Extract version from filename: DCDSetup1.6.0.36-X64.exe -> 1.6.0.36
$InstallerName = $DownloadLink.split("/")[-1]
if ($InstallerName -match 'DCDSetup([\d.]+)') {
    $LatestWebVersion = RemoveTrailingZeros $Matches[1]
} else {
    WriteLog "ERROR: Could not parse version from installer filename: $InstallerName"
    exit 1
}

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
