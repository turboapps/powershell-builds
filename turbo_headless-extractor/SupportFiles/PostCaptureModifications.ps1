$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add Chrome as dependency

# At the moment pushes with client fail unless dependency hashes are valid. However, client can still resolve latest version even with an invalid hash
# if the hash field in the config is at least 32 bytes (config load fails otherwise)
#AddDependency "google" "chrome" "" "0000000000000000000000000000000000000000000000000000000000000000" $False

# Get latest Chrome info
$repo = "google/chrome"
$version = GetCurrentHubVersion $repo
$hash = GetCurrentHubHash $repo

if ($version -and $hash)
{
    AddDependency "google" "chrome" "$version" "$hash" $False
}

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically run the script
AddStartupFile "powershell" "" "C:\extractor\Extract.ps1" $True "AnyCpu"