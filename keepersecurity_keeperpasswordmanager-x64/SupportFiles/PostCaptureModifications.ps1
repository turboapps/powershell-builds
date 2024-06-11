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
