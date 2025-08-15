$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

########################
# Edit ShellExtentions #
########################

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")

# Delete all ShellExtension nodes to remove duplicates
$ShellExtensions.SelectNodes("ShellExtension") | ForEach-Object { $_.ParentNode.RemoveChild($_) | Out-Null }

# Create new ShellExtension nodes
# Get the startupfile path
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$command = $StartupFiles.SelectSingleNode("StartupFile[@tag='MobaRTE']").node
$commandPath = Split-Path $command

$commandString = "$command -contextdiff &quot;%1&quot;"
$iconPath = "$commandPath\MobaRTE_MOBADIFF.ico"
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Compare using MobaDiff")
$node.SetAttribute("command",$commandString)
$node.SetAttribute("iconPath",$iconPath)
$ShellExtensions.AppendChild($node)

$commandString = "$command -contextedit &quot;%1&quot;"
$iconPath = "$commandPath\MobaRTE_MAINICON.ico"
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Edit with MobaTextEditor")
$node.SetAttribute("command",$commandString)
$node.SetAttribute("iconPath",$iconPath)
$ShellExtensions.AppendChild($node)