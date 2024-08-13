Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use the vendor index to get the version
$nodejsIndex = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json

# Find the first version where the .lts property is not $false
$firstLTSVersion = $nodejsIndex | Where-Object { $_.lts -ne $false } | Select-Object -First 1
$LTSVersion = $firstLTSVersion.version

$DownloadLink = "https://nodejs.org/dist/$LTSVersion/node-$LTSVersion-x64.msi"
$InstallerName = "node-$LTSVersion-x64.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
