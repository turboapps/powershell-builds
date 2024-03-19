Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Get main download page for application.
$URL = 'https://cran.r-project.org/bin/windows/Rtools/'

$Page = curl $URL -UseBasicParsing

# Split up the download link table rows and look for the R-release version.
$TableRows = $Page.Content -split "<tr>"

# Find the table row with the release version of R Tools.
$LatestVersion = ""
$LatestVersionLink = ""
ForEach ($TableRow in $TableRows)
{

  If ($TableRow -like "*R-release*") 
  {
   # Parse the <a href=""> link for the release version.
   $LatestVersionLink = (($TableRows[2] -split "<a href=""") -split """>")[1]
   
   # Parse the link segment for the latest version. Used in assembling the download link.
   $LatestVersion = ($LatestVersionLink -split "/")[0]
   
   break
  }
}


$Page2 = curl ($URL + $LatestVersionLink) -UseBasicParsing

# Get the right link for the installer executable. Note duplicate Rtools installer links (sources) and arm64 installer in the next release.
$DownloadLink = ($Page2.Links | Where-Object { ($_.outerHTML -like '*>Rtools* installer<*') -and ($_.href -like '*.exe') }) | Select-Object -ExpandProperty href
$DownloadLink = $URL + $LatestVersion + "/" + $DownloadLink

# Name of the downloaded installer file
$InstallerName = Split-Path -Path $DownloadLink -Leaf

$Installer = wget $DownloadLink -O $DownloadPath\$InstallerName

$LatestWebVersion = Get-VersionFromExe "$DownloadPath\$InstallerName"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}