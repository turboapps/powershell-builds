
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
## $VirtualizationSettings.chromiumSupport = [string]$true  ## NOT REQUIRED 
$virtualizationSettings.isolateWindowClasses = [string]$true
$virtualizationSettings.launchChildProcsAsUser = [string]$true

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

# Set MachineSid - allows Chrome user settings to be portable between devices using the same sandbox
$MachineSid = $xappl.Configuration.SelectSingleNode("Device").SelectSingleNode("MachineSid")
$MachineSid.InnerText = "S-1-5-21-992951991-166803189-1664049914"

# Edit ObjectMaps - Isolating this message window allows multiple Chrome instances to run side-by-side.
$ObjectMaps = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ObjectMaps")
$node = $xappl.CreateElement("ObjectMap")
$node.SetAttribute("value","window://Chrome_MessageWindow:0")
$ObjectMaps.AppendChild($node)

# Edit Extensions - the default turbo capture is missing some of the extensions - adding in .htm, .html, .svg, .xht, .xhtml
$Extensions = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Extensions")

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".htm")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","text/html")
$Extensions.AppendChild($node)

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".html")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","text/html")
$Extensions.AppendChild($node)

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".svg")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","")
$Extensions.AppendChild($node)

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".xht")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","")
$Extensions.AppendChild($node)

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".xhtml")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","")
$Extensions.AppendChild($node)

$node = $xappl.CreateElement("Extension")
$node.SetAttribute("name",".xml")
$node.SetAttribute("progId","MSEdgeHTM")
$node.SetAttribute("mimeType","")
$Extensions.AppendChild($node)

###################
# Edit Filesystem #
###################

$Filesystem = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Filesystem")

# Set the noSync attribute on the LOCALAPPDATA\Microsoft\Edge and subfolders
$parentNode = $Filesystem.SelectNodes("Directory[@name='@APPDATALOCAL@']/Directory[@name='Microsoft']/Directory[@name='Edge']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("noSync", "False")
}

# Sets Isolation on the folders
$Filesystem.SelectSingleNode("Directory[@name='@APPDATALOCAL@']/Directory[@name='Microsoft']/Directory[@name='Edge']").isolation = "Full"

## Remove script log file directory
$Filesystem.SelectNodes("Directory[@name='@DESKTOP@']/Directory[@name='Package']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"

$Registry = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Registry")

# Set Full isolation on HKCU\Software\Microsoft\Edge and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Edge']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Full isolation on HKLM\Software\WOW6432Node\Microsoft\Edge and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='Edge']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Full isolation on HKLM\Software\WOW6432Node\Microsoft\EdgeUpdate and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='EdgeUpdate']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Full isolation on HKLM\Software\Microsoft\Edge and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='Edge']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}

# Delete registry keys - unnecessary keys
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SYSTEM']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

# This will add the ProgIDs for HTTP and HTTPS allowing users to set Edge as the default browser
# Create Classes reg keys for http and https
AddRegKey "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Classes']" "http" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Classes']/Key[@name='http']" "URL Protocol" "Full" "False" "False" "String" ""
AddRegKey "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Classes']" "https" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='Classes']/Key[@name='https']" "URL Protocol" "Full" "False" "False" "String" ""
# Duplicating with upper case CLASSES
AddRegKey "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='CLASSES']" "http" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='CLASSES']/Key[@name='http']" "URL Protocol" "Full" "False" "False" "String" ""
AddRegKey "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='CLASSES']" "https" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='Software']/Key[@name='CLASSES']/Key[@name='https']" "URL Protocol" "Full" "False" "False" "String" ""

# Clone the MSEdgeHTM ProgID node to http and https
$EdgeHtmlNode = $xappl.SelectSingleNode("//ProgId[@name='MSEdgeHTM']").CloneNode($true)
# Modify the ProgId name and description for HTTP and HTTPS
$httpNode = $EdgeHtmlNode.Clone()
$httpNode.SetAttribute("name", "http")
$httpNode.SetAttribute("description", "URL:HyperText Transfer Protocol")
$httpsNode = $EdgeHtmlNode.Clone()
$httpsNode.SetAttribute("name", "https")
$httpsNode.SetAttribute("description", "URL:HyperText Transfer Protocol with Privacy")
# Append HTTP and HTTPS ProgIds to the XML structure
$xappl.SelectSingleNode("//ProgIds").AppendChild($httpNode)
$xappl.SelectSingleNode("//ProgIds").AppendChild($httpsNode)