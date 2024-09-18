$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add a new startup file, so running the image will automatically start yt-dlp (need to layer in ffmpeg if higher quality downloads desired)
AddStartupFile "@SYSDRIVE@\yt-dlp\yt-dlp.exe" "" "" $True "AnyCpu"