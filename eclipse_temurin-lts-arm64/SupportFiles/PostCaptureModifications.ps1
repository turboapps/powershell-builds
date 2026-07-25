$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

####################
# Environment Vars #
####################

# Get the folder the JDK was extracted to
$InstallDir = Get-ChildItem -Path "c:\Program Files\Eclipse Adoptium" -Directory | Where-Object { $_.Name -like 'jdk*' }

$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
# Add the jdk bin directory to the PATH env var
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@PROGRAMFILES@\Eclipse Adoptium\$InstallDir\bin"
# Add the JAVA_HOME env var
AddEnvVar "JAVA_HOME" "Inherit" "Replace" "" "@PROGRAMFILES@\Eclipse Adoptium\$InstallDir"