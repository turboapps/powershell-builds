$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Get latest Chrome info
$repo = "google/chrome"
$chromeVersion = GetCurrentHubVersion $repo
$chromeHash = GetCurrentHubHash $repo

# Add Chrome as dependency
AddDependency "google" "chrome" "$chromeVersion" "$chromeHash" $False

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically run the script
AddStartupFile "C:\extractor\Extract.ps1" "" "" $True "AnyCpu"