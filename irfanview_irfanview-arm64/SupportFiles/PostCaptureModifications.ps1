$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

## Update startup file to main IrfanView application rather than Thumbnail viewer.
## Null-guarded and exe matched by prefix - the arm64 build's exe name is not guaranteed to be i_view64.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
# Set default to False for all startup files to disable them on launch.
$defaultNode = $StartupFiles.SelectSingleNode("StartupFile[@default='True']")
if ($defaultNode) { $defaultNode.default = 'False' }
# Set default to True for the main application exe that doesn't have any arguments.
$mainExeNode = $StartupFiles.SelectSingleNode("StartupFile[starts-with(@node,'@PROGRAMFILES@\IrfanView\i_view') and @commandLine='']")
if ($mainExeNode) { $mainExeNode.SetAttribute("default", "True") }
