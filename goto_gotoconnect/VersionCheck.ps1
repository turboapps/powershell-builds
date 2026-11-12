Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the headless-extractor to get the download link (a plain web request now gets 403 from support.goto.com)
$url = "https://support.goto.com/connect/help/what-are-the-download-links-for-it-admin-deployments"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull --format=json turbo/headless-extractor
turbo run turbo/headless-extractor --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

# Get the per-machine 32-bit installer link for the latest version
$DownloadLink = Get-Content -Path "$outputdir\links.txt" | Where-Object { $_ -match '/GoToSetupMachine-[\d.]+-ia32\.msi$' } | Select-Object -First 1
if (-not $DownloadLink) { throw "No GoToSetupMachine ia32 .msi link found on $url (see $outputdir\dom.html)" }

$InstallerName = $DownloadLink.Split("/")[-1]

$LatestWebVersion = $InstallerName.Split("-")[1]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
