$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!INCLUDE\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.shutdownProcessTree = [string]$true

###################
# Edit Services   #
###################

$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")

# Disable autostart for all services
ForEach ($Service in $Services.SelectNodes("Service")) {
  $Service.start = "LoadOnDemand"
}