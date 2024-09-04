Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Name of the downloaded installer file
$Installer = "$SupportFiles\Autodesk_DWG_TrueView_en-US_setup_webinstall.exe"

# Run the install creator to download and extract the media to C:\Autodesk
$ProcessExitCode = RunProcess $Installer "-d C:\Autodesk" $False

# Check for the completion of the AdODIS-installer.exe process which means the media was downloaded and extracted
    DO {        
        $InstallerRunning = CheckRunningProcess "AdODIS-installer"  # wait for the process to start 
        Start-Sleep -Seconds 10
        } While ($InstallerRunning -ne 1)
    DO {         
        $InstallerRunning = CheckRunningProcess "AdODIS-installer"  # wait for the process to end
        Start-Sleep -Seconds 10
        } While ($InstallerRunning -ne 0)

# kill the installer process
taskkill.exe /f /im Autodesk_DWG_TrueView_en-US_setup_webinstall.exe /t

# Find the setup.xml from the installer folder
$setupFilePath = Get-ChildItem -Path "C:\autodesk" -Recurse -Filter "setup.xml" | Select-Object -First 1
$SetupXML = $setupFilePath.FullName

WriteLog "Setup.xml found: $SetupXML"

# Get the latest version tag from the setup.xml file
[xml]$xml = Get-Content -Path $SetupXML
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$namespaceManager.AddNamespace("ns", "https://emsfs.autodesk.com/schema/manifest/1/0")
$buildNumberNode = $xml.SelectSingleNode("//ns:BuildNumber", $namespaceManager)

$LatestWebVersion = $buildNumberNode.'#text'
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

$LatestWebVersion = "20" + $LatestWebVersion

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}