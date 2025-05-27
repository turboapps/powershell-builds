$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$virtualizationSettings.isolateWindowClasses = [string]$true
$virtualizationSettings.launchChildProcsAsUser = [string]$true


######################
# Edit Startup Files #
######################
# Get the path to the Ssms.exe file
$ssmsDir = Get-ChildItem -Path "C:\Program Files (x86)" -Recurse -Filter "Ssms.exe" -ErrorAction SilentlyContinue
$installDir = $ssmsDir.Directory.FullName
$installDir = $installDir -replace [regex]::Escape("${env:ProgramFiles(x86)}"), "@PROGRAMFILESX86@"
$installDir

## Change the container startup file to SSMS.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@node='$installDir\Microsoft.AnalysisServices.Deployment.exe']").default = 'False'
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='$installDir\Ssms.exe']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\SQL Server Management Studio and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='SQL Server Management Studio']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}
# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\VisualStudio and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='VisualStudio']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}
# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\VSCommon and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='VSCommon']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}

#################
# Edit Files    #
#################
# Change folder and subfolders from Merge to WriteCopy isolation
PushFolderIsolation "Directory[@name='@APPDATALOCAL@']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@APPDATA@']/descendant-or-self::*" "Merge" "WriteCopy"
