Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# downloads.php defaults to Linux instructions, so ask for the Windows ZIP list explicitly.
$Page = Invoke-WebRequest -Uri 'https://www.php.net/downloads.php?os=windows&osvariant=windows-downloads&version=default' -UseBasicParsing

# Read the version out of the x64 NTS .zip name.
$PhpMatch = [regex]::Match($Page.Content, 'href="https://[^"]+/php-(?<ver>\d+(?:\.\d+)+)-nts-Win32-vs\d+-x64\.zip"', 'IgnoreCase')
if (-not $PhpMatch.Success) {
    WriteLog "Could not find an x64 NTS .zip link on the PHP downloads page. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}

# Get installer link for latest version
$LatestWebVersion = $PhpMatch.Groups['ver'].Value

# We are removing any trailing zeroes from the version
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
