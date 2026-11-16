Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$Page = curl 'https://www.sketchup.com/en/download/all' -UseBasicParsing

# Get download page for latest version.
$DownloadLink = ($Page.Links | Where-Object {$_.href -like "*.exe*"}).href[0]

# Name of the downloaded installer file
$InstallerName = $DownloadLink.split("/")[-1]

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# The exe's version resource only contains a short version (e.g. 25.0.660) without the build number,
# so get the full version (e.g. 2025.0.660.288) from the downloaded exe's file name (e.g. SketchUp-2025-0-660-288.exe).
if ((Split-Path "$Installer" -Leaf) -match '(\d+)-(\d+)-(\d+)-(\d+)\.exe$') {
    $LatestWebVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
} else {
    # Fall back to the exe version info, converting the 2-digit major version (25) to the year format (2025).
    $ExeVersion = (Get-VersionFromExe "$Installer").Split(".")
    if ([int]$ExeVersion[0] -lt 100) { $ExeVersion[0] = [string](2000 + [int]$ExeVersion[0]) }
    $LatestWebVersion = $ExeVersion -join "."
}
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}