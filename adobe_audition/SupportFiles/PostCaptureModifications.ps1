$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true

# Add the folder @APPDATA@\Adobe\Common to workaround a DB.dqlite3 error when launching on virtual machines.
# Can be removed when bug APPQ-3840 is resolved
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Adobe']" "Common" "Full" "False" "False"