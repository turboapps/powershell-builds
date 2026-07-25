$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

## Update startup file to git-cmd rather than git-bash.
 ## Null-guarded: the ARM64 capture does not register the same startup-file set as x64
 ## (the x64 recipe's node lookups came back empty and the bare method calls killed the
 ## whole post-capture step). If git-cmd.exe was not captured as a startup file, add it
 ## as the default instead of dereferencing a missing node.
 $StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
 if (-not $StartupFiles) {
     $StartupFiles = $xappl.Configuration.AppendChild($xappl.CreateElement("StartupFiles"))
 }
 # Set default to False for all startup files to disable them on launch.
 $defaultStartupFile = $StartupFiles.SelectSingleNode("StartupFile[@default='True']")
 if ($defaultStartupFile) { $defaultStartupFile.SetAttribute("default", "False") }
 # Set default to True for the git-cmd executable
 $gitCmdStartupFile = $StartupFiles.SelectSingleNode("StartupFile[@node='@PROGRAMFILES@\Git\git-cmd.exe']")
 if ($gitCmdStartupFile) {
     $gitCmdStartupFile.SetAttribute("default","True")
 } else {
     AddStartupFile "@PROGRAMFILES@\Git\git-cmd.exe" "" "" $True "AnyCpu"
 }

 # Add a new startup file for headless mode "C:\Program Files\Git\cmd\git.exe"
 AddStartupFile "@PROGRAMFILES@\Git\cmd\git.exe" "headless" "" $False "AnyCpu"