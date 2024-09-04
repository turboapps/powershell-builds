$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically use java to start the tika jar in GUI mode (need to have java installed or layered in)
AddStartupFile "java" "" "-jar @SYSDRIVE@\tika\tika-app.jar" $True "AnyCpu"