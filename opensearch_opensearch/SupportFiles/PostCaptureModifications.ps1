$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")

# Isolate the JAVA_HOME environment variable in order to avoid conflicts with a native instance of the variable and default the behavior to use OpenSearch's included JDK.
AddEnvVar "JAVA_HOME" "Full" "Replace" "" ""

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.
# We use the the opensearch-windows-install.bat instead of bin\opensearch.bin to ensure config settings are refreshed on every launch (almost no launch perf difference).

$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")

# Add a new startup file for "C:\opensearch\opensearch-windows-install.bat"
$node = $xappl.CreateElement("StartupFile")
$node.SetAttribute("node","@SYSDRIVE@\opensearch\opensearch-windows-install.bat")
$node.SetAttribute("tag","start")
$node.SetAttribute("commandLine","")
$node.SetAttribute("default","True")
$node.SetAttribute("architecture","AnyCpu")
$StartupFiles.AppendChild($node)