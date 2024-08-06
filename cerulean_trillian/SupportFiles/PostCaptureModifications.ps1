$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add a startup script
$Scripts = $xappl.Configuration.SelectSingleNode("Scripts")
$Scripts.SetAttribute("startup", "C:\Scripts\trillianINI.cmd")
$Scripts.SetAttribute("runAsAdmin", "false")
$Scripts.SetAttribute("exitOnNonZeroReturnValue", "false")