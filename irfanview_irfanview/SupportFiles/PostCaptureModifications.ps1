$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

## Update startup file to main IrfanView application rather than Thumbnail viewer.
 $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
 # Set default to False for all startup files to disable them on launch.
 $StartupFiles.SelectSingleNode("StartupFile[@default='True']").default = 'False'
 # Set default to True for the main application exe that doesn't have any arguments.
 ($StartupFiles.SelectSingleNode("StartupFile[@node='@PROGRAMFILESX86@\IrfanView\i_view32.exe' and @commandLine='']")).SetAttribute("default","True")
