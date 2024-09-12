$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add Java Runtime Environment as dependency

# At the moment pushes with client fail unless dependency hashes are valid. However, client can still resolve latest version even with an invalid hash
# if the hash field in the config is at least 32 bytes (config load fails otherwise)
#AddDependency "oracle" "jre" "" "0000000000000000000000000000000000000000000000000000000000000000" $False

# Get latest JRE info
$repo = "oracle/jre"
$version = GetCurrentHubVersion $repo
$hash = GetCurrentHubHash $repo

if ($version -and $hash)
{
    AddDependency "oracle" "jre" "$version" "$hash" $False
}

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically use java to start the tika jar in GUI mode (need to have java installed or layered in)
AddStartupFile "java" "" "-jar @SYSDRIVE@\tika\tika-app.jar" $True "AnyCpu"