$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


######################
# Edit Startup Files #
######################
## Change the container startup file to BCompare.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@node='@WINDIR@\Installer\{44E72A8E-80FF-4B71-B049-3D28A07B63BF}\BCompare.ico']").default = 'False'
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@PROGRAMFILES@\Beyond Compare 4\BCompare.exe']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}