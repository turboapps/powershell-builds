Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Apache stopped publishing Windows installers after NetBeans 25 (dlcdn netbeans-installers/ is now empty).
# The Windows installer is now published by Friends of Apache NetBeans (FoAN) on GitHub, tagged nbXX.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Release = Invoke-RestMethod -Uri "https://api.github.com/repos/Friends-of-Apache-NetBeans/netbeans-installers/releases/latest" -UseBasicParsing

$LatestWebVersion = $Release.tag_name -replace '^nb', ''
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
