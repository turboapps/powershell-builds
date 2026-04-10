Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$releases = Invoke-RestMethod "https://api.github.com/repos/HydrologicEngineeringCenter/hec-downloads/releases?per_page=20"
$asset = $releases | ForEach-Object { $_.assets } |
    Where-Object { $_.name -like "HEC-RAS_*_Setup.exe" -and $_.name -notlike "*with_Linux*" } |
    Select-Object -First 1

if (-not $asset) {
    WriteLog "ERROR: Could not find HEC-RAS setup asset in recent GitHub releases."
    exit 1
}

$DownloadLink = $asset.browser_download_url
$InstallerName = $asset.name
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
