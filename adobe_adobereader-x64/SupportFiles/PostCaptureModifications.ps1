$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true

<# This is not required if installing with  DISABLE_NOTIFICATIONS=1 property
# Add ChildProcessException for msiexec to prevent UAC prompt from repair after Adobe SignIn
$ChildProcessVirtualization = $xappl.Configuration.SelectSingleNode("VirtualizationSettings").SelectSingleNode("ChildProcessVirtualization")
$node = $xappl.CreateElement("ChildProcessException")
$node.SetAttribute("name","msiexec.exe")
$ChildProcessVirtualization.AppendChild($node)
#>


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