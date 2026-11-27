Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Latest "Current Channel" build from the official update history page (see !include\OfficeHelpers.ps1)
$LatestWebVersion = RemoveTrailingZeros "$(Get-LatestOfficeCurrentChannelVersion)"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
