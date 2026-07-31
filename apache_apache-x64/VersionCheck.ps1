Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# apachelounge.com rejects the default PowerShell user agent with a protocol error.
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Get installer link for latest version
$Page = Invoke-WebRequest -Uri 'https://www.apachelounge.com/download/' -UseBasicParsing

# Read the version out of the Win64 .zip name. The arch token case is inconsistent on the page
# (Win64 vs win32) and the VS number changes with each toolchain bump, so match case-insensitively.
$ALMatch = [regex]::Match($Page.Content, "href=`"/download/VS\d+/binaries/httpd-(?<ver>\d+(?:\.\d+)+)-\d+-Win64-VS\d+\.zip`"", 'IgnoreCase')
if (-not $ALMatch.Success) {
    WriteLog "Could not find a Win64 httpd .zip link on the Apache Lounge download page. Exiting."
    WriteLog "BuildResult=Failed"
    Exit 1
}

# Get installer link for latest version
$LatestWebVersion = $ALMatch.Groups['ver'].Value

# We are removing any trailing zeroes from the version
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
