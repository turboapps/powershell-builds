Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg
$HubVersion = $HubVersion.Split(" ")[-1]

#############################################
## Get latest version from the vendor site ##
#############################################

# Use this section to get the latest version 
# either from the vendor website or the downloaded installer file

# Get installer link for latest version
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x86.exe -OutFile "$DownloadPath\vc_redist.x86.exe"

$LatestWebVersion = Get-VersionFromExe "$DownloadPath\vc_redist.x86.exe"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}