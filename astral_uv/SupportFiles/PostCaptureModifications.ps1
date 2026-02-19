$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################
# Add a new startup file, so running the image will automatically start the main executable
AddStartupFile "@SYSDRIVE@\UV\uv.exe" "" "" $True "AnyCpu"