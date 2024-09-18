$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically run the script (need to have chrome installed or layered in)
AddStartupFile "powershell" "" "-ExecutionPolicy Bypass C:\extractor\Extract.ps1" $True "AnyCpu"