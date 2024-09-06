Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# The content of this page is built by javascript so we need to use Edge in headless mode to get the content
$url = "https://aka.ms/pbireportserver"
$Page = EdgeGetContent -url $url -headlessMode "old"

# Split the content into lines
$lines = $Page -split "`n"

# Use regex to match URLs that end with PBIDesktopSetupRS.exe
$regex = '(https://download.microsoft.com/download/[a-zA-Z0-9/-]+/PBIDesktopSetupRS\.exe)'

# Find matches in the input string
$matches = [regex]::matches($lines, $regex)

$DownloadLink = $matches[0].Value

$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}