$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


######################
### Edit Services  ###
######################
$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")
# Disable autostart for all services to speed up launch time.
ForEach ($Service in $Services.SelectNodes("Service")) {
  $Service.start = "LoadOnDemand"
}