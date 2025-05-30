$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

## Update startup file to git-cmd rather than git-bash.
 $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
 # Set default to False for all startup files to disable them on launch.
 $StartupFiles.SelectSingleNode("StartupFile[@default='True']").default = 'False'
 # Set default to True for the git-cmd executable
 ($StartupFiles.SelectSingleNode("StartupFile[@node='@PROGRAMFILES@\Git\git-cmd.exe']")).SetAttribute("default","True")

 # Add a new startup file for headless mode "C:\Program Files\Git\cmd\git.exe"
 AddStartupFile "@PROGRAMFILES@\Git\cmd\git.exe" "headless" "" $False "AnyCpu"