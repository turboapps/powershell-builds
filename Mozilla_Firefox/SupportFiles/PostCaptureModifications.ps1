
################
#   FUNCTIONS  #
################

# Adds a registry key to a parent - usage example: AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Google']" "Chrome" "Full" "False" "False"
Function AddRegKey($parentKey,$name,$isolation,$readOnly,$hide,$noSync) {
$parentNode = $Registry.SelectSingleNode($parentKey)
$node = $xappl.CreateElement("Key")
$node.SetAttribute("name",$name)
$node.SetAttribute("isolation",$isolation)
$node.SetAttribute("readOnly",$readOnly)
$node.SetAttribute("hide",$hide)
$node.SetAttribute("noSync",$noSync)
$parentNode.AppendChild($node)
}

# Adds a registry value to a parent - usage example: AddRegValue "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Google']" "Chrome" "Full" "False" "False" "String" "some string"
Function AddRegValue($parentKey,$name,$isolation,$readOnly,$hide,$type,$value) {
$parentNode = $Registry.SelectSingleNode($parentKey)
$node = $xappl.CreateElement("Value")
$node.SetAttribute("name",$name)
$node.SetAttribute("isolation",$isolation)
$node.SetAttribute("readOnly",$readOnly)
$node.SetAttribute("hide",$hide)
$node.SetAttribute("type",$type)
$node.SetAttribute("value",$value)
$parentNode.AppendChild($node)
}

# Modifies an existing registry value - usage example: EditRegValue "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Google']/Value[@name='Version']" "Full" "False" "False" "String" "102.1.4"
Function EditRegValue($parentKey,$isolation,$readOnly,$hide,$type,$value) {
$node = $Registry.SelectSingleNode($parentKey)
$node.SetAttribute("isolation",$isolation)
$node.SetAttribute("readOnly",$readOnly)
$node.SetAttribute("hide",$hide)
$node.SetAttribute("type",$type)
$node.SetAttribute("value",$value)
}


#######################

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
#$virtualizationSettings.launchChildProcsAsUser = [string]$true

# Configure metadata for the application
$StandardMetaData = $xappl.Configuration.SelectSingleNode("StandardMetadata")

If ($AppName -ne $null){
    $StandardMetaData.SelectNodes('StandardMetadataItem[@Name="Title"]') | ForEach-Object {$_.ParentNode.RemoveChild($_)}  # Remove entries if they exist
    $node = $xappl.CreateElement("StandardMetadataItem") # Set Title meta
    $node.SetAttribute("property","Title")
    $node.SetAttribute("value",$AppName)
    $StandardMetaData.AppendChild($node)
}
If ($Vendor -ne $null){ 
    $StandardMetaData.SelectNodes('StandardMetadataItem[@Name="Publisher"]') | ForEach-Object {$_.ParentNode.RemoveChild($_)}
    $node = $xappl.CreateElement("StandardMetadataItem") # Set Publisher meta
    $node.SetAttribute("property","Publisher")
    $node.SetAttribute("value",$Vendor)
    $StandardMetaData.AppendChild($node)
}
If ($AppDesc -ne $null){ 
    $StandardMetaData.SelectNodes('StandardMetadataItem[@Name="Description"]') | ForEach-Object {$_.ParentNode.RemoveChild($_)}
    $node = $xappl.CreateElement("StandardMetadataItem") # Set Description meta
    $node.SetAttribute("property","Description")
    $node.SetAttribute("value",$AppDesc)
    $StandardMetaData.AppendChild($node)
}
If ($VendorURL -ne $null){ 
    $StandardMetaData.SelectNodes('StandardMetadataItem[@Name="Website"]') | ForEach-Object {$_.ParentNode.RemoveChild($_)} 
    $node = $xappl.CreateElement("StandardMetadataItem") # Set Website meta
    $node.SetAttribute("property","Website")
    $node.SetAttribute("value",$VendorURL)
    $StandardMetaData.AppendChild($node)
}
If ($InstalledVersion -ne $null){
    $StandardMetaData.SelectNodes('StandardMetadataItem[@Name="Version"]') | ForEach-Object {$_.ParentNode.RemoveChild($_)}
    $node = $xappl.CreateElement("StandardMetadataItem") # Set Version meta
    $node.SetAttribute("property","Version")
    $node.SetAttribute("value",$InstalledVersion)
    $StandardMetaData.AppendChild($node)
}

######################
# Edit Startup Files #
######################

$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")

######################
# Edit Shortcuts #
######################

$Shortcuts = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Shortcuts")

###################
# Edit Services #
###################

$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")

###################
# Edit Filesystem #
###################

$Filesystem = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Filesystem")

## Remove script log file directory
$Filesystem.SelectNodes("Directory[@name='@DESKTOP@']/Directory[@name='Package']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


$Registry = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Registry")

# Set Full isolation on HKCU\SOFTWARE\Mozilla\Firefox\Launcher - This fixes an issue loading web pages if Firefox is installed natively
$Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Mozilla']/Key[@name='Firefox']/Key[@name='Launcher']").isolation= "Full"
$Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Mozilla']/Key[@name='Firefox']/Key[@name='Launcher']").isolation= "Full"

# Add and Hide reg key HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\<extension>\UserChoice
# This will prevent Edge from taking over the HTML,HTM,PDF,SHTML,SVG,WEBP,WEBM,XHT,XHTML file associations
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']" "FileExts" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".htm" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".html" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".pdf" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".shtml" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".svg" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".webm" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".webp" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".xht" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".xhtml" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.htm']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.html']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.pdf']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.shtml']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.svg']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.webm']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.webp']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.xht']" "UserChoice" "Hide" "False" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.xhtml']" "UserChoice" "Hide" "False" "False" "False"
