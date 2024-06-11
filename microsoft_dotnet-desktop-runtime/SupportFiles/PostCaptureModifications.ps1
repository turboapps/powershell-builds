$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Filesystem #
###################

# Remove the Turbo folders that get captured
$Filesystem.SelectNodes("Directory[@name='@APPDATACOMMON@']/Directory[@name='Turbo']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

# Remove the WinGet folders that get captured
$Filesystem.SelectNodes("Directory[@name='@APPDATALOCAL@']/Directory[@name='Microsoft']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }


####################
# Environment Vars #
####################

$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
# Add the dotnet directory to the PATH env var
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILESX86@\dotnet"
# Specifies whether .NET welcome and telemetry messages are displayed on the first run.
# https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-environment-variables#dotnet_nologo
AddEnvVar "DOTNET_NOLOGO" "Inherit" "Replace" "" "true"