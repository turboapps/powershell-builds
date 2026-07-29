$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.handleExplorerShellEx = [string]$true

###################
# Edit Services #
###################

$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")

## Turn off AutoLoad for ZoomCptService
# Null-guarded: arm64 captures don't always register the same services as x64
$ZoomCptService = $Services.SelectSingleNode("Service[@name='ZoomCptService']")
if ($ZoomCptService) { $ZoomCptService.start = "LoadOnDemand" }


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set Hide isolation on HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\zoommsirepair to prevent MSI healing
# Null-guarded: arm64 captures don't always produce the same registry tree as x64
$ZoomMsiRepair = $Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='RunOnce']/Value[@name='zoommsirepair']")
if ($ZoomMsiRepair) { $ZoomMsiRepair.isolation = "Hide" }