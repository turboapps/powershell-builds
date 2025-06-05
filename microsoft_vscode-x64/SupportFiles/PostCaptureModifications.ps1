$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true


###############################
# Edit Named Object Isolation #
###############################

# Isolate the vscode basednamedojbect to allow running multiple instances side-by-side.
# Pipe is versioned, ex 39ba74c1-1.90.2-main-sock, 39ba74c1-1.89.1-main-sock.
$NamedObjectIsolation = $xappl.Configuration.SelectSingleNode("NamedObjectIsolation")

$node = $xappl.CreateElement("Exception")
$node.SetAttribute("regex","main-sock")
$NamedObjectIsolation.AppendChild($node)
