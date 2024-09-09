$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add Java Runtime Environment as dependency
# Don't need to actually specify version or hash, client can still resolve latest version even without a specific hash but need to at least
# put something with 32 bytes in the hash field for the dependency otherwise config won't load
AddDependency "oracle" "jre" "" "0000000000000000000000000000000000000000000000000000000000000000" $False

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically use java to start the tika jar in GUI mode (need to have java installed or layered in)
AddStartupFile "java" "" "-jar @SYSDRIVE@\tika\tika-app.jar" $True "AnyCpu"