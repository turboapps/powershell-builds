$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$virtualizationSettings.isolateWindowClasses = [string]$true
$virtualizationSettings.launchChildProcsAsUser = [string]$true


######################
# Edit Startup Files #
######################
## Change the container startup file to SSMS.exe
## The SSMS 22 capture also brings in the Visual Studio Installer, whose exe gets
## auto-registered as a default startup file and would launch instead of SSMS.
## Disable every startup file, then enable only Ssms.exe (matched by filename -
## the VS-installer-based layout makes the full path unreliable).
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
foreach ($sf in $StartupFiles.SelectNodes("StartupFile")) {
    if ($sf.node -like '*\Ssms.exe') {
        $sf.SetAttribute("default", "True")
    }
    else {
        $sf.SetAttribute("default", "False")
    }
}

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\SQL Server Management Studio and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='SQL Server Management Studio']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}
# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\VisualStudio and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='VisualStudio']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}
# Set WriteCopy isolation on @HKCU@\SOFTWARE\Microsoft\VSCommon and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='VSCommon']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}

#################
# Edit Files    #
#################
# Change folder and subfolders from Merge to WriteCopy isolation
PushFolderIsolation "Directory[@name='@APPDATALOCAL@']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@APPDATA@']/descendant-or-self::*" "Merge" "WriteCopy"
