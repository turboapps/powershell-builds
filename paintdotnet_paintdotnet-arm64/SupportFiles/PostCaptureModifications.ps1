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
$Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']").AppendChild($node)

## Set HKLM\SOFTWARE\paint.net registry key and its children to full isolation
## Null-guarded: arm64 captures don't always produce the same registry tree as x64
$paintKeys = @(
    "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']",
    "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']/Key[@name='Capabilities']",
    "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='paint.net']/Key[@name='Capabilities']/Key[@name='FileAssociations']"
)
foreach ($keyPath in $paintKeys) {
    $keyNode = $Registry.SelectSingleNode($keyPath)
    if ($keyNode) { $keyNode.isolation = "Full" }
}
