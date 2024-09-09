$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add Chrome as dependency
# Don't need to actually specify version or hash, client can still resolve latest version even without a specific hash but need to at least
# put something with 32 bytes in the hash field for the dependency otherwise config won't load
AddDependency "google" "chrome" "" "0000000000000000000000000000000000000000000000000000000000000000" $False

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically run the script
AddStartupFile "powershell" "" "C:\extractor\Extract.ps1" $True "AnyCpu"