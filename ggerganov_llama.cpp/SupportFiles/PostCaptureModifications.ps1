$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################

# Since this is not an application install, we have to set the startup file manually.

# Add startup files for all llama tools with triggers. None are startup files by default
$Builds = "noavx","avx","avx2","avx512","cuda-cu12.2.0"
foreach ($Build in $Builds) {
    AddStartupFile "@SYSDRIVE@\llama-$Build\llama-cli.exe" "llama-cli-$Build" "" $False "AnyCpu"
    AddStartupFile "@SYSDRIVE@\llama-$Build\llama-server.exe" "llama-server-$Build" "" $False "AnyCpu"
    AddStartupFile "@SYSDRIVE@\llama-$Build\llama-llava-cli.exe" "llama-llava-cli-$Build" "" $False "AnyCpu"
}