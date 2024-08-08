$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true

###################
# Edit Filesystem #
###################

# Sets Isolation on the folders
$Filesystem.SelectSingleNode("Directory[@name='@PROGRAMFILES@']/Directory[@name='WindowsApps']").isolation = "Full"

####################
# Environment Vars #
####################

# Find the path to the winget.exe
$exePath = Get-ChildItem -Path "C:\Program Files\WindowsApps" -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
$parentFolder = Split-Path -Path $exePath -Parent
$wingetFolder = Split-Path -Path $parentFolder -Leaf

# Append the path to the folder that contains winget.exe to the PATH environment variable
$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILES@\WindowsApps\$wingetFolder"