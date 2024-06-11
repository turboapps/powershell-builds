Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

WriteLog "Downloading the latest MSIX installer."
# Get installer link for latest version
$DownloadLink = "https://www.keepersecurity.com/desktop_electron/packages/KeeperPasswordManager.msixbundle"

# Name of the downloaded installer file
$InstallerName = "KeeperPasswordManager.zip"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract ZIP archive.
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "$DownloadPath\Extracted"

# Rename the unzipped APPX file to extract it
Copy-Item -Path "$DownloadPath\Extracted\KeeperPasswordManager-x64.appx" -Destination "$DownloadPath\Extracted\KeeperPasswordManager-x64.zip"

# Extract ZIP archive.
Expand-Archive -Path "$DownloadPath\Extracted\KeeperPasswordManager-x64.zip" -DestinationPath "$DownloadPath\Extracted\KeeperPasswordManager-x64"

$LatestWebVersion = Get-VersionFromExe "$DownloadPath\Extracted\KeeperPasswordManager-x64\app\keeperpasswordmanager.exe"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}