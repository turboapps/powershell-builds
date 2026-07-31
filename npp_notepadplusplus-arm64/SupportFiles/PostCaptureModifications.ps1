$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

########################
# Edit ShellExtentions #
########################

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Edit with Notepad++")
$node.SetAttribute("command","@PROGRAMFILES@\Notepad++\notepad++.exe ""%1""")
$node.SetAttribute("iconPath","@PROGRAMFILES@\Notepad++\notepad++.exe")
$ShellExtensions.AppendChild($node)