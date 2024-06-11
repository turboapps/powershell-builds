$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true

# Edit ObjectMaps - Add ObjectMap node to add a network ip restriction deny action to dl.pstmn.io
# Preventing network access to ip://dl.pstmn.io will prevent the application from checking for updates
$ObjectMaps = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ObjectMaps")
$node = $xappl.CreateElement("ObjectMap")
$node.SetAttribute("value","ip://dl.pstmn.io@0.0.0.0")
$ObjectMaps.AppendChild($node)