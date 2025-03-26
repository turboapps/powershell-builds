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

# Download the latest msix installer
$DownloadLink = "https://go.microsoft.com/fwlink/?linkid=2195164"
$InstallerName = "Microsoft.OutlookForWindows_x64.msix"
$MSIX = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# use 7zip to extract the msix to get the version from the olk.exe
. turbo try 7-zip/7-zip --isolate=merge --startup-file=@PROGRAMFILESX86@\7-Zip\7z.exe -- x $MSIX -o"$DownloadPath\Microsoft.OutlookForWindows_x64"

$olkExe = "$DownloadPath\Microsoft.OutlookForWindows_x64\olk.exe"

$LatestWebVersion = Get-VersionFromExe $olkExe
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}