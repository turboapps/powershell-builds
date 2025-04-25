$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true

###################
# Edit Filesystem #
###################

# Delete the Squirrel update executable, this will prevent auto update checks
# It will also prevent users from manually running update checks
$Xappl.SelectSingleNode("//File[@name='Update.exe']").ParentNode.RemoveChild($Xappl.SelectSingleNode("//File[@name='Update.exe']"))
