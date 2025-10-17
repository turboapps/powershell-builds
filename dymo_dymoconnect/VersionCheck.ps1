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

# Define a regular expression pattern
$pattern = '.*/dymo/Software/Win/.*'

# Filter and output lines containing matching links
foreach ($line in $links) {
    if ($line -match $pattern) {
        $DownloadLink = $line  # Directly use the matching URL
    }
}

$InstallerName = $DownloadLink.split("/")[-1]
$Installer = Join-Path -Path $DownloadPath -ChildPath $InstallerName
. curl.exe $DownloadLink -o $Installer

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
