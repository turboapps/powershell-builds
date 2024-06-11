Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Have to download the installer and check its meta for the actual version.
$DownloadLink = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B2CC0992A-8A31-8D75-167C-5C46238DE706%7D%26lang%3Den%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEW/dl/chrome/install/googlechromestandaloneenterprise64.msi"

# Name of the downloaded installer file
$InstallerName = "googlechromestandaloneenterprise.msi"

# Installer file object
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

# Read the comments field from the file meta using the Windows Shell object.
# The MSI installer lists a different version under the MSI ProductVersion field that cannot be converted back to the Chrome version.
$InstallerFolder = (New-Object -ComObject Shell.Application).NameSpace((Split-Path $Installer))
## Set property index to 24 to get the Comments file meta field.
## Split the comments at the Copyright part and grab the first string for the version.
$LatestWebVersion = ($InstallerFolder.GetDetailsOf($InstallerFolder.parsename((Split-Path -Leaf $Installer)),24) -split " Copyright")[0]
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}