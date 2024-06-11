$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set Full isolation on HKLM\SOFTWARE\Adobe and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Adobe']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Write-copy isolation on HKLM\SOFTWARE\Adobe
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Adobe']").isolation= "WriteCopy"

# Set Full isolation on HKLM\SOFTWARE\WOW6432Node\Adobe and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Adobe']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Write-copy isolation on HKLM\SOFTWARE\WOW6432Node\Adobe
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Adobe']").isolation= "WriteCopy"

######################
# Edit Shortcuts #
######################
# Rename shortcuts from "Adobe Acrobat" to "Adobe Acrobat Pro"
# required if Acrobat Pro and Acrobat Reader will  be installed on the same device as they share the same shortcut names
$Shortcuts = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Shortcuts")
$Shortcuts.SelectSingleNode("Folder[@name='Desktop']/Shortcut[@name='Adobe Acrobat']").name = 'Adobe Acrobat Pro'
$Shortcuts.SelectSingleNode("Folder[@name='Programs Menu']/Shortcut[@name='Adobe Acrobat']").name = 'Adobe Acrobat Pro'

########################
# Edit ShellExtentions #
########################

# The shell extension is currently breaking the windows zip extract utility - we will remove it until the bug is resolved
$xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ShellExtensions") | ForEach-Object { $_.ParentNode.RemoveChild($_) }