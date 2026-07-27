$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# This is an addon image for the ollama/ollama-x64 package.
# No startup file is added; dot-sourcing PostCaptureFunctions.ps1 above applies the standard metadata.
