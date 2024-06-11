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

$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILES@\WindowsApps\Microsoft.DesktopAppInstaller_1.22.10582.0_x64__8wekyb3d8bbwe"