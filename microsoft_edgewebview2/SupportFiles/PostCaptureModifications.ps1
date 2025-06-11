$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Filesystem #
###################

#Remove folder @PROGRAMFILESX86@\Microsoft\EdgeUpdate
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESX86@']/Directory[@name='Microsoft']/Directory[@name='EdgeUpdate']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

# Set Full isolation on HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='EdgeUpdate']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
