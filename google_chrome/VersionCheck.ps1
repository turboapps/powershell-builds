Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Have to download the installer and check its meta for the actual version.
$DownloadLink = "https://dl.google.com/tag/s/appguid={00000000-0000-0000-0000-000000000000}&iid={00000000-0000-0000-0000-000000000000}&lang=$language&browser=3&usagestats=0&appname=Google%20Chrome&installdataindex=defaultbrowser&needsadmin=prefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi"

# Name of the downloaded installer file
$InstallerName = "googlechromestandaloneenterprise.msi"

# Installer file object
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Read the comments field from the file meta using the Windows Shell object.
# The MSI installer lists a different version under the MSI ProductVersion field that cannot be converted back to the Chrome version.
$InstallerFolder = (New-Object -ComObject Shell.Application).NameSpace((Split-Path $Installer))
## Set property index to 24 to get the Comments file meta field.
## Split the comments at the Copyright part and grab the first string for the version.
$LatestWebVersion = ($InstallerFolder.GetDetailsOf($InstallerFolder.parsename((Split-Path -Leaf $Installer)),24) -split " Copyright")[0]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}