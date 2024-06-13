$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Filesystem #
###################

# No changes.

######################
# Edit Startup Files #
######################


## Change the container startup file to WINPROJ.EXE for Project.

## Needs workaround due to bug in Office transform. Uncomment and remove workaround on next Studio release.
# $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
# $parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@PROGRAMFILES@\Microsoft Office\Office16\WINPROJ.EXE']")
# ForEach ($childNodes in $parentNode) {
#    $childNodes.SetAttribute("default", "True")
# }

# Workaround is to manually add the startup file:
AddStartupFile "@PROGRAMFILES@\Microsoft Office\Office16\WINPROJ.EXE" "WINPROJ" "" $True "AnyCpu"

