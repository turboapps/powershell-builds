$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################
## Change the container startup file to putty.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@node='@SYSDRIVE@\PuTTY\pageant.exe']").default = 'False'
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@SYSDRIVE@\PuTTY\putty.exe']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}