$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


# Set Full isolation on HKCU\SOFTWARE\Mozilla\Firefox\Launcher - This fixes an issue loading web pages if Firefox is installed natively
# Null-guarded: arm64 captures don't always produce the same registry tree as x64
$LauncherKey = $Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Mozilla']/Key[@name='Firefox']/Key[@name='Launcher']")
if ($LauncherKey) { $LauncherKey.isolation = "Full" }


#################
# Other Changes #
#################

# Clone the OPEN verb to TURBOCLIENT_v24.2_LEGACY_PROGID for http and https ProgIDs
# Null-guarded: skip any ProgId/verb the arm64 capture did not register
foreach ($progIdName in @('http', 'https')) {
    $ProgIDNode = $xappl.SelectSingleNode("//ProgId[@name='$progIdName']")
    $openVerbNode = if ($ProgIDNode) { $ProgIDNode.SelectSingleNode(".//Verb[@name='open']") } else { $null }
    if ($openVerbNode) {
        $newVerbNode = $openVerbNode.Clone()
        $newVerbNode.SetAttribute("name", "TURBOCLIENT_v24.2_LEGACY_PROGID")
        $ProgIDNode.AppendChild($newVerbNode)
    }
}