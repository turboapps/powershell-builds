Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# The VS 2022 release channel manifest reports the current release, eg "17.14.39 (August 2026)".
# The same channel serves x64 and ARM64 - there is no separate ARM64 release train.
# This matches the version vswhere reports after install (catalog_productDisplayVersion), which is what the image gets tagged with.
$Channel = Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/channel" -UseBasicParsing

# Keep only the leading dotted version number
$LatestWebVersion = [regex]::Match("$($Channel.info.productDisplayVersion)", '^\d+(\.\d+)+').Value

# We are removing any trailing zeroes from the version
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
