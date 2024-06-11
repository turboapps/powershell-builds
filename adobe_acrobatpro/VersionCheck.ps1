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

## Determine the latest version of installer
Wget https://armmf.adobe.com/arm-manifests/win/SCUP/AcrobatCatalog-DC.cab -OutFile "$DownloadPath\AcrobatCatalog.cab"
## Expand cab to XML.
Expand "$DownloadPath\AcrobatCatalog.cab" -F:* "$DownloadPath\AcrobatCatalog.xml"

## Parse XML for latest version
[XML]$AcrobatCatalog = Get-Content("$DownloadPath\AcrobatCatalog.xml")
$Versions = $AcrobatCatalog.SystemsManagementCatalog.SoftwareDistributionPackage.InstallableItem.ApplicabilityRules.MetaData.MsiPatchMetaData.MsiPatch.TargetProduct.UpdatedVersion | Sort-Object -Descending
$LatestWebVersion = $Versions[0]

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"
# Add "20" for the year to the version
$LatestWebVersion = "20" + $LatestWebVersion

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}