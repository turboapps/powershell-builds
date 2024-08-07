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
$CurrentVersion = $nodejsIndex.version[0]

$DownloadLink = "https://nodejs.org/dist/$CurrentVersion/node-$CurrentVersion-x64.msi"
$InstallerName = "node-$CurrentVersion-x64.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
