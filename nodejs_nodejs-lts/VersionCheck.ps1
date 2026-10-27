Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Pinned to 22.23.4 on this branch instead of the newest LTS from the vendor index
$LTSVersion = "v22.23.4"

$DownloadLink = "https://nodejs.org/dist/$LTSVersion/node-$LTSVersion-x64.msi"
$InstallerName = "node-$LTSVersion-x64.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

# No Compare-Versions on this branch: the hub already holds a newer LTS (24.x), which
# would exit the build before the pinned 22.23.4 is captured.
WriteLog "Version compare skipped: building pinned $LatestWebVersion (hub has $HubVersion)."

}
