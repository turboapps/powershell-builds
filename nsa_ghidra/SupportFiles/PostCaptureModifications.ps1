$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.
# We use the the ghidraRun.bat from the extracted ZIP folder.

# Add a new startup file for "C:\ghidra\ghidraRun.bat"
AddStartupFile "@SYSDRIVE@\ghidra\ghidraRun.bat" "start" "" $True "AnyCpu"

# Add a new startup file for headless mode "C:\ghidra\support\analyzeHeadless.bat"
AddStartupFile "@SYSDRIVE@\ghidra\support\analyzeHeadless.bat" "headless" "" $False "AnyCpu"