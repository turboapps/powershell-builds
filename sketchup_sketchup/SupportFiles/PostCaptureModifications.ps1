$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################

## Change the container startup file to Skethup.exe
# Remove auto-start flag from all
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@default='True']").default = 'False'
# Set auto-launch for Skethchup
$parentNode = $StartupFiles.SelectSingleNode("StartupFile[@tag='SketchUp']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}
