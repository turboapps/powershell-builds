$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################
## Change the container startup file to putty.exe
## Null-guarded: arm64 captures don't always auto-register the same StartupFiles as x64
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$pageantNode = $StartupFiles.SelectSingleNode("StartupFile[@node='@SYSDRIVE@\PuTTY\pageant.exe']")
if ($pageantNode) { $pageantNode.default = 'False' }
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@SYSDRIVE@\PuTTY\putty.exe']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}