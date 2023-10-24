Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get installer link for latest version
$DownloadLink = "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x86"
$InstallerName = "ZoomInstallerFull.msi"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Note this will only work if the MSI is digitally signed
$MSIVersion = Get-AppLockerFileInformation -Path $Installer | Select -ExpandProperty Publisher | select BinaryVersion
$LatestWebVersion =  [string]$MSIVersion.BinaryVersion.MajorPartNumber +'.'+ [string]$MSIVersion.BinaryVersion.MinorPartNumber +'.'+ [string]$MSIVersion.BinaryVersion.BuildPartNumber | Out-String

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "Version on Vendor website: $LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}