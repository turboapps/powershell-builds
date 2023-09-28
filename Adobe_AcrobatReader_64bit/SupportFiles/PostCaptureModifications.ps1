
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

# Set Full isolation on HKLM\Software\Adobe and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Adobe']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Write-copy isolation on HKLM\Software\Adobe
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Adobe']").isolation= "WriteCopy"

# Set Full isolation on HKLM\Software\WOW6432Node\Adobe and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='WOW6432Node']/Key[@name='Adobe']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Write-copy isolation on HKLM\Software\WOW6432Node\Adobe
$Registry.SelectSingleNode("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='WOW6432Node']/Key[@name='Adobe']").isolation= "WriteCopy"

# Add reg key HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice
# This will prevent Edge from taking over the PDF file association
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']" "FileExts" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".pdf" "WriteCopy" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.pdf']" "UserChoice" "WriteCopy" "False" "False"
# Duplicating because sometimes 'SOFTWARE' is 'Software'
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']" "FileExts" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".pdf" "WriteCopy" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.pdf']" "UserChoice" "WriteCopy" "False" "False"

##################################################
# Create new layer with Pre-Win11 as a condition #
##################################################
# We need this layer because Win10 behaves differently than Win11 when you set Acrobat as the default application to open PDF documents.
# The UserChoice registry key needs to be set to Hide isolation on Win10 but on Win11 that will cause the OS to prompt for an app to open with every time a PDF is double clicked.

$Layers = $xappl.Configuration.Layers # Get layers node
$node = $xappl.CreateElement("Layer") # Create PreWin11Layer for systems lower than Win11
$node.SetAttribute("name","PreWin11Layer")
$Layers.PrependChild($node)

$PreWin11Layer = $Layers.SelectSingleNode("Layer[@name='PreWin11Layer']") # Create Condition, so layer only applies to OSes lower than Win11
$node = $xappl.CreateElement("Condition")
$node.SetAttribute("variable","OS")
$node.SetAttribute("operator","LessEqual")
$node.SetAttribute("value","Win10")
$PreWin11Layer.AppendChild($node)

$node = $xappl.CreateElement("Registry")  # Create the registry node in our new layer
$PreWin11Layer.AppendChild($node)

$Registry = $PreWin11Layer.SelectSingleNode("Registry") # Create the root registry keys that we need to add keys to
$node = $xappl.CreateElement("Key")
$node.SetAttribute("name","@HKCU@")
$node.SetAttribute("isolation","Merge")
$node.SetAttribute("readOnly","False")
$node.SetAttribute("hide","False")
$node.SetAttribute("noSync","False")
$Registry.AppendChild($node)


# Add and Hide reg key HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice
# This will prevent Edge from taking over the PDF file association

AddRegKey "Key[@name='@HKCU@']" "SOFTWARE" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']" "Microsoft" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']" "Windows" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']" "CurrentVersion" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']" "Explorer" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']" "FileExts" "Merge" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']" ".pdf" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Explorer']/Key[@name='FileExts']/Key[@name='.pdf']" "UserChoice" "Hide" "False" "False"