$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


## Change the container startup file from soffice tag to soffice2 tag (the one without the --safe-mode parameter
 $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
 $StartupFiles.SelectSingleNode("StartupFile[@tag='soffice']").default = 'False'
 
 $soffice2Node = $StartupFiles.SelectSingleNode("StartupFile[@tag='soffice2']")
 $soffice2Node.SetAttribute("default", "True")
