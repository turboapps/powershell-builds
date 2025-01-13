$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

########################
# Edit ShellExtentions #
########################

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","TreeSize")
$node.SetAttribute("command","""@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe"" /SCAN ""%1""")
$node.SetAttribute("iconPath","@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe")
$ShellExtensions.AppendChild($node)

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Find files")
$node.SetAttribute("command","""@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe"" /SEARCH /TABS ""Basic Search"" /SCAN ""%1""")
$node.SetAttribute("iconPath","@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe")
$ShellExtensions.AppendChild($node)

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Find duplicate files")
$node.SetAttribute("command","""@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe"" /SEARCH:Start /TABS ""Duplicate Search"" /SCAN ""%1""")
$node.SetAttribute("iconPath","@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe")
$ShellExtensions.AppendChild($node)

$ShellExtensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions")
$node = $xappl.CreateElement("ShellExtension")
$node.SetAttribute("description","Advanced File Search")
$node.SetAttribute("command","""@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe"" /SEARCH /TABS CustomSearch /SCAN ""%1""")
$node.SetAttribute("iconPath","@PROGRAMFILES@\JAM Software\TreeSize\TreeSize.exe")
$ShellExtensions.AppendChild($node)