$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


## Change the container startup file from soffice tag to soffice2 tag (the one without the --safe-mode parameter
## Null-guarded: arm64 captures don't always auto-register the same StartupFiles as x64
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$sofficeNode = $StartupFiles.SelectSingleNode("StartupFile[@tag='soffice']")
if ($sofficeNode) { $sofficeNode.default = 'False' }

$soffice2Node = $StartupFiles.SelectSingleNode("StartupFile[@tag='soffice2']")
if ($soffice2Node) { $soffice2Node.SetAttribute("default", "True") }
