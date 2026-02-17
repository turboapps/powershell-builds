Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

WriteLog "Downloading the latest MSI installer."

# 32bit Adobe Reader version is typically one release back from the 64bit
# We need to get the second release version from the Release Notes page

# Get latest version for Acrobat Reader from their SCUP page.
## Download SCUP cab.
Wget https://armmf.adobe.com/arm-manifests/win/SCUP/ReaderCatalog-DC.cab -OutFile "$DownloadPath\ReaderCatalog.cab"
## Expand cab to XML.
Expand "$DownloadPath\ReaderCatalog.cab" -F:* "$DownloadPath\ReaderCatalog.xml"

## Parse XML for latest version
[XML]$ReaderCatalog = Get-Content("$DownloadPath\ReaderCatalog.xml")

# Get latest versions (already sorted descending)
$Versions = $ReaderCatalog.SystemsManagementCatalog.
    SoftwareDistributionPackage.InstallableItem.
    ApplicabilityRules.MetaData.
    MsiPatchMetaData.MsiPatch.TargetProduct.
    UpdatedVersion |
    Sort-Object -Descending |
    Select-Object -Unique

$InstallerName = "AcroRdrDC.exe"
$Installer = $null

# Try the first 4 versions
foreach ($RawVersion in $Versions | Select-Object -First 4) {

    $Version = $RawVersion -replace '\.', ''
    $DownloadLink = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/$Version/AcroRdrDC${Version}_fr_FR.exe"

    WriteLog "Attempting download for version $Version"
    WriteLog "URL: $DownloadLink"

    try {
        # IMPORTANT: must throw on failure
        $Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName -ErrorAction Stop

        if (Test-Path $Installer) {
            WriteLog "Download succeeded for version $Version"
            break
        }
        else {
            throw "Installer file missing after download."
        }
    }
    catch {
        WriteLog "Download failed for version $Version"
        WriteLog $_.Exception.Message
        $Installer = $null
    }
}

if (-not $Installer) {
    throw "Failed to download Acrobat Reader installer after trying 4 versions."
}

$LatestWebVersion = $RawVersion
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}