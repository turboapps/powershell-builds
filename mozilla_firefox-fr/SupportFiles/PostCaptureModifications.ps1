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
$Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Mozilla']/Key[@name='Firefox']/Key[@name='Launcher']").isolation= "Full"

#################
# Other Changes #
#################

# Clone the OPEN verb to TURBOCLIENT_v24.2_LEGACY_PROGID for http and https ProgIDs
$ProgIDNode = $xappl.SelectSingleNode("//ProgId[@name='http']")
$openVerbNode = $ProgIDNode.SelectSingleNode(".//Verb[@name='open']")
$newVerbNode = $openVerbNode.Clone()
$newVerbNode.SetAttribute("name", "TURBOCLIENT_v24.2_LEGACY_PROGID")
$ProgIDNode.AppendChild($newVerbNode)
$ProgIDNode = $xappl.SelectSingleNode("//ProgId[@name='https']")
$openVerbNode = $ProgIDNode.SelectSingleNode(".//Verb[@name='open']")
$newVerbNode = $openVerbNode.Clone()
$newVerbNode.SetAttribute("name", "TURBOCLIENT_v24.2_LEGACY_PROGID")
$ProgIDNode.AppendChild($newVerbNode)