# Set variables used by all functions
$Filesystem = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Filesystem")
$Registry = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Registry")
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")

#########################
# PostCapture Functions #
#########################

# Pushes folder isolation level $newiso to all folders from a parent folder if the current isolation is $currentiso
# This example will set WriteCopy isolation on @PROGRAMFILES@\Adobe and all subfolders that are currently set to Merge
# Usage example: PushFolderIsolation "Directory[@name='@PROGRAMFILES@']/Directory[@name='Adobe']" "Merge" "WriteCopy"
Function SetFolderIsolation($parentDir,$currentiso,$newiso) {
    $parentNode = $Filesystem.SelectNodes("$parentDir")
    ForEach ($childNodes in $parentNode) {
        # Check if the current isolation attribute is set to $currentiso
        if ($childNodes.GetAttribute("isolation") -eq $currentiso) {
            # Set the isolation attribute to $newiso
            $childNodes.SetAttribute("isolation", $newiso)
        }
    }
}


# Adds a directory to a parent - usage example: AddDirectory "Directory[@name='@PROGRAMFILES@']/Directory[@name='Adobe']/Directory[@name='Acrobat']" "Prefs" "Full" "False" "False"
Function AddDirectory($parentDir,$name,$isolation,$readOnly,$hide,$noSync) {
  $parentNode = $Filesystem.SelectSingleNode($parentDir)
  $node = $xappl.CreateElement("Directory")
  $node.SetAttribute("name",$name)
  $node.SetAttribute("isolation",$isolation)
  $node.SetAttribute("readOnly",$readOnly)
  $node.SetAttribute("hide",$hide)
  $node.SetAttribute("noSync",$noSync)
  $parentNode.AppendChild($node)
}

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

# Adds a startup file - usage example: AddStartupFile "@SYSDRIVE@\opensearch\opensearch-windows-install.bat" "start" "" $True "AnyCpu"
Function AddStartupFile($name,$tag,$commandLine,$default,$arch) {
  $parentNode = $StartupFiles
  $node = $xappl.CreateElement("StartupFile")
  $node.SetAttribute("node",$name)
  $node.SetAttribute("tag",$tag)
  $node.SetAttribute("commandLine",$commandLine)
  $node.SetAttribute("default",$default)
  $node.SetAttribute("architecture",$arch)
  $parentNode.AppendChild($node)
}


Function SetMetaData {
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
}



## Set the metadata for each build
SetMetaData

## Remove script log file directory from each build
$Filesystem.SelectNodes("Directory[@name='@DESKTOP@']/Directory[@name='Package']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }