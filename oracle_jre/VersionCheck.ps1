Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$url = "https://www.java.com/en/download/manual.jsp"
$Page = EdgeGetContent -url $url

# Split the content into lines
$lines = $Page -split "`n"

# Define a regular expression pattern
$pattern = 'Download Java software for Windows'

# Filter and output lines containing matching links
foreach ($line in $lines) {
    if ($line -match $pattern) {
        $DownloadLink = [regex]::Match($line, 'href="([^"]+)"').Groups[1].Value
        break
    }
}

$InstallerName = "jre-windows.exe"
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = Get-VersionFromExe $Installer
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"
# Remove any middle .0 from the version
$LatestWebVersion = $LatestWebVersion -replace '\.0\.', '.'

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}