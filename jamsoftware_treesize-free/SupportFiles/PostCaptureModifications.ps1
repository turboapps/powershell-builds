$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

########################
# Edit ShellExtentions #
########################

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Scan with TreeSize Free")
$node.SetAttribute("command","""@APPDATALOCAL@\Programs\JAM Software\TreeSize Free\TreeSizeFree.exe"" ""%1""")
$node.SetAttribute("iconPath","@APPDATALOCAL@\Programs\JAM Software\TreeSize Free\TreeSizeFree.exe")
$ShellExtensions.AppendChild($node)