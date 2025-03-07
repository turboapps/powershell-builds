Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the headless-extractor to get the download link
$url = "https://www.java.com/en/download/manual.jsp"
$outputdir = "$DownloadPath\links"
turbo config --domain=turbo.net
turbo pull turbo/headless-extractor
turbo run turbo/headless-extractor --using=google/chrome --isolate=merge-user --startup-file=powershell -- C:\extractor\Extract.ps1 -OutputDir $outputdir -Url $url -DOM -ExtractLinks

$links = Get-Content -Path "$outputdir\links.txt"

$javaLinks = $links | Where-Object { $_ -match "https://javadl\.oracle\.com/webapps/download/AutoDL\?BundleId=" }
$DownloadLink = $javaLinks[-1]

$InstallerName = "jre-windows-x64.exe"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"
# Remove any middle .0 from the version
$LatestWebVersion = $LatestWebVersion -replace '\.0\.', '.'

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}