$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Services #
###################

$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")

## Turn off AutoLoad for ZoomCptService
$Services.SelectSingleNode("Service[@name='ZoomCptService']").start= "LoadOnDemand"


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set Hide isolation on HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\zoommsirepair to prevent MSI healing
$Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='RunOnce']/Value[@name='zoommsirepair']").isolation= "Hide"