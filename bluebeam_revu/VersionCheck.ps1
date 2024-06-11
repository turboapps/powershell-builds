Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Download the latest EXE
$InstallerName = "BluebeamRevu.exe"
$Installer = Invoke-WebRequest -Uri 'https://bluebeam.com/FullRevuTRIAL' -OutFile $DownloadPath\$InstallerName -UseBasicParsing

$LatestWebVersion = Get-VersionFromExe $DownloadPath\$InstallerName
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}