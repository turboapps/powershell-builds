Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Use this section to get the latest version 
# either from the vendor website or the downloaded installer file

# Get installer link for latest version
$DownloadLink = "https://go.microsoft.com/fwlink/?linkid=2196106"

# Name of the downloaded installer file
$InstallerName = "Teams_windows_x64.zip"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Extract ZIP archive.
Expand-Archive -Path $DownloadPath\$InstallerName -DestinationPath "$DownloadPath\Extracted"

$LatestWebVersion = Get-VersionFromExe "$DownloadPath\Extracted\ms-teams.exe"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}