$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true

# Add a new startup file, so running the image will automatically start mongod.exe
# Find the path to the mongod.exe
$startupFilePath = Get-ChildItem -Path "C:\Program Files\MongoDB" -Recurse -Filter "mongod.exe" | Select-Object -ExpandProperty DirectoryName
$startupFileParent = (Get-Item $startupFilePath).Parent.FullName

AddStartupFile "$startupFilePath\mongod.exe" "" "--dbpath=`"$startupFileParent\data`"" $True "AnyCpu"