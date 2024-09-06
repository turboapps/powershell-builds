Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# The content of this page is built by javascript so we need to use Edge in headless mode to get the content
$url = "https://www.dymo.com/support?cfid=user-guide"
$Page = EdgeGetContent -url $url -headlessMode "old"

# Split the content into lines
$lines = $Page -split "`n"
#$lines | Out-File -FilePath "$env:TEMP\dymopage.txt" -Append

# Define a regular expression pattern
$pattern = 'href="([^"]+\.exe)"'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $DownloadLink = $matches[1]  # Use the first link that matches *.exe*
        $DownloadLink
        break
    }
}
$InstallerName = $DownloadLink.split("/")[-1]
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
