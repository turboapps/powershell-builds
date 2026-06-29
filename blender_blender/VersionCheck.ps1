Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# --- Hop 1: main download page -> the /download/release/... link ---
$page = Invoke-WebRequest -Uri 'https://www.blender.org/download/'  -UseBasicParsing
$ReleaseLink = ([regex]::Matches($page.Content, 'https?://[^"'' ]*?\.msi/?') |
                ForEach-Object { $_.Value } | Select-Object -Unique |
                Where-Object { $_ -match 'windows-x64' } | Select-Object -First 1)

# --- Hop 2: the Thanks page -> the real mirror URLs ---
$thanks  = Invoke-WebRequest -Uri $ReleaseLink -UseBasicParsing
$mirrors = [regex]::Matches($thanks.Content, 'https?://[^"'' ]*?blender-[^"'' ]*?\.msi') |
           ForEach-Object { $_.Value } | Select-Object -Unique

# Prefer the official direct server, fall back to the first mirror
$DownloadLink = $mirrors | Where-Object { $_ -match 'download\.blender\.org' } | Select-Object -First 1
if (-not $DownloadLink) { $DownloadLink = $mirrors | Select-Object -First 1 }

Write-Output "Real download URL: $DownloadLink"

# --- Hop 3: download the actual MSI ---
$InstallerName = [regex]::Match($DownloadLink, '[^/]+\.msi').Value
$Installer = DownloadInstaller $DownloadLink $DownloadPath $InstallerName

$LatestWebVersion = [regex]::Match($InstallerName, 'blender-(\d+\.\d+(?:\.\d+)?)-windows').Groups[1].Value
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"
WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
