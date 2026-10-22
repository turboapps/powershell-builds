$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

####################
# Environment Vars #
####################

# Add the PHP folder to the system PATH. Isolation is Inherit and mergeMode is Prepend, so the
# container sees the host PATH with this prepended - that puts php ahead of any host copy.
$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
# Installing the VC++ runtime can leave a captured PATH behind. Drop any PATH the capture picked
# up so the entry below is the only one, rather than ending up with two competing PATH nodes.
$EnvironmentVariablesEx.SelectNodes("VariableEx[translate(@name,'PATH','path')='path']") | ForEach-Object { $_.ParentNode.RemoveChild($_) | Out-Null }
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@SYSDRIVE@\php"

######################
# Edit Startup Files #
######################

# PHP is an extracted .zip rather than an install, so the startup files are set manually.
# php is the default: running the image with no tag starts the CLI.
$PhpDir = "@SYSDRIVE@\php"
AddStartupFile "$PhpDir\php.exe"     "php"     "" $True  "AnyCpu"
AddStartupFile "$PhpDir\php-win.exe" "php-win" "" $False "AnyCpu"
AddStartupFile "$PhpDir\php-cgi.exe" "php-cgi" "" $False "AnyCpu"
AddStartupFile "$PhpDir\phpdbg.exe"  "phpdbg"  "" $False "AnyCpu"
