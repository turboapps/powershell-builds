$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Add a new startup file for headless mode "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
AddStartupFile "@PROGRAMFILES@\OpenSSL-Win64\bin\openssl.exe" "headless" "" $False "AnyCpu"