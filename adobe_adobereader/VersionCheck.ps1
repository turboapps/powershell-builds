Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################


## Determine the latest version of installer
Wget https://armmf.adobe.com/arm-manifests/win/SCUP/ReaderCatalog-DC.cab -OutFile "$DownloadPath\ReaderCatalog.cab"
## Expand cab to XML.
Expand "$DownloadPath\ReaderCatalog.cab" -F:* "$DownloadPath\ReaderCatalog.xml"

## Parse XML for latest version
[XML]$ReaderCatalog = Get-Content("$DownloadPath\ReaderCatalog.xml")
$Versions = $ReaderCatalog.SystemsManagementCatalog.SoftwareDistributionPackage.InstallableItem.ApplicabilityRules.MetaData.MsiPatchMetaData.MsiPatch.TargetProduct.UpdatedVersion | Sort-Object -Descending
$LatestWebVersion = $Versions[0]

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}