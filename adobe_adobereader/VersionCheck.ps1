Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# 32bit Adobe Reader version is typically one release back from the 64bit
# We need to get the second release version from the Release Notes page

## Determine the latest version of installer
Wget https://armmf.adobe.com/arm-manifests/win/SCUP/ReaderCatalog-DC.cab -OutFile "$DownloadPath\ReaderCatalog.cab"
## Expand cab to XML.
Expand "$DownloadPath\ReaderCatalog.cab" -F:* "$DownloadPath\ReaderCatalog.xml"

## Parse XML for latest version
[XML]$ReaderCatalog = Get-Content("$DownloadPath\ReaderCatalog.xml")
$Versions = $ReaderCatalog.SystemsManagementCatalog.SoftwareDistributionPackage.InstallableItem.ApplicabilityRules.MetaData.MsiPatchMetaData.MsiPatch.TargetProduct.UpdatedVersion | Sort-Object -Descending | Select-Object -Unique
$LatestWebVersion = $Versions[1]

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}