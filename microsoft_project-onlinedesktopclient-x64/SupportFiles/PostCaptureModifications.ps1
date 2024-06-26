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
 $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
 $parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@PROGRAMFILES@\Microsoft Office\Office16\WINPROJ.EXE']")
 ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
 }



