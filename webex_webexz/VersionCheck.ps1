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
$DownloadLink = "https://binaries.webex.com/WebexTeamsDesktop-Windows-Gold/Webex_x86_en.msi"

# Name of the downloaded installer file
$InstallerName = "Webex_en.msi"

$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-MsiProductVersion "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}