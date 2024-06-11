$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


######################
# Edit Startup Files #
######################
## Change the container startup file to python.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@tag='pythonw']").default = 'False'
$parentNode = $StartupFiles.SelectNodes("StartupFile[@tag='python']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}