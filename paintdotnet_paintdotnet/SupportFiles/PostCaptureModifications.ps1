$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Filesystem #
###################

## Add Current User Directory\Local Application Data\paint.net directory
$node = $xappl.CreateElement("Directory")
$node.SetAttribute("name","paint.net")
$node.SetAttribute("isolation","Full")
$node.SetAttribute("readOnly","False")
$node.SetAttribute("hide","False")
$node.SetAttribute("noSync","True")
$Filesystem.SelectNodes("Directory[@name='@APPDATALOCAL@']").AppendChild($node)


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

## Add HKCU\SOFTWARE\paint.net registry key
$node = $xappl.CreateElement("Key")
$node.SetAttribute("name","paint.net")
$node.SetAttribute("isolation","Full")
$node.SetAttribute("readOnly","False")
$node.SetAttribute("hide","False")
$node.SetAttribute("noSync","False")
$Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']").AppendChild($node)

## Set HKLM\SOFTWARE\paint.net registry key and its children to full isolation
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']").isolation = "Full"
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']/Key[@name='Capabilities']").isolation = "Full"
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']/Key[@name='Capabilities']/Key[@name='FileAssociations']").isolation = "Full"
