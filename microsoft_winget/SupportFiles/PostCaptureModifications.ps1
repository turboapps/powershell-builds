
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

# Adds an environment variable - usage example: AddEnvVar "JAVA_HOME" "Full" "Replace" "" "C:\path\to\java"
Function AddEnvVar($name,$isolation,$mergeMode,$mergeString,$value) {
$parentNode = $EnvironmentVariablesEx
$node = $xappl.CreateElement("VariableEx")
$node.SetAttribute("name",$name)
$node.SetAttribute("isolationMode",$isolation)
$node.SetAttribute("mergeMode",$mergeMode)
$node.SetAttribute("mergeString",$mergeString)
$node.SetAttribute("value",$value)
$parentNode.AppendChild($node)
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

# Sets Isolation on the folders
$Filesystem.SelectSingleNode("Directory[@name='@PROGRAMFILES@']/Directory[@name='WindowsApps']").isolation = "Full"

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


$Registry = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Registry")

####################
# Environment Vars #
####################

$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILES@\WindowsApps\Microsoft.DesktopAppInstaller_1.22.10582.0_x64__8wekyb3d8bbwe"