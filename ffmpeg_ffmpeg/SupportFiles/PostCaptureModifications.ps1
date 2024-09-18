$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add the ffmpeg bin directory to the PATH env var
$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@SYSDRIVE@\ffmpeg\bin"

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically start ffmpeg
AddStartupFile "ffmpeg" "ffmpeg" "" $True "AnyCpu"

# Add startup files for the other utilities as well
AddStartupFile "ffplay" "ffplay" "" $False "AnyCpu"
AddStartupFile "ffprobe" "ffprobe" "" $False "AnyCpu"