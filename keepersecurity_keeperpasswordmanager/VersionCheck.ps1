Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get installer link for latest version
$DownloadLink = "https://www.keepersecurity.com/desktop_electron/Win32/KeeperSetup32.msi"

# Name of the downloaded installer file
$InstallerName = "KeeperSetup32.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = (Get-AppLockerFileInformation -Path $Installer).Publisher.BinaryVersion
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}