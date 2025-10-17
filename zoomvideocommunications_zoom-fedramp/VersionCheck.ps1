Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the headless-extractor to get the download link
$url = "https://zoomgov.com/download"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome-x64 --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

# Loop through the lines and find the first .msi link
$DownloadLink = $null
foreach ($link in $links) {
    if ($link -match "ZoomInstallerFull.msi") {
        $DownloadLink = $link
        break
    }
}

# Name of the downloaded installer file
$InstallerName = "ZoomInstallerFull.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = $DownloadLink.Split("/")[-2]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
