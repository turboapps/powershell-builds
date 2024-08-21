$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


# Get the folder the jre was installed to
$jredir = Get-ChildItem -Path "c:\Program Files\Java" -Directory | Where-Object { $_.Name -like 'jre*' }

# Add the java paths to the PATH env var
$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILES@\Java\$jredir\bin;@PROGRAMFILESCOMMONX86@\Oracle\Java\java8path"

# Remove all variables from the <EnvironmentVariables> node
$EnvironmentVariables = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariables")
$EnvironmentVariables.ParentNode.RemoveChild($EnvironmentVariables)