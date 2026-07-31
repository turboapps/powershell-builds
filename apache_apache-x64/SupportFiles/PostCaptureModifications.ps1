$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

####################
# Environment Vars #
####################

# Add the Apache bin directory to the system PATH. Isolation is Inherit and mergeMode is Prepend,
# so the container sees the host PATH with this prepended - that puts httpd, openssl, ab and the
# other Apache tools ahead of any host copies. Setting the machine PATH during the capture instead
# would bake the whole build machine's PATH into the image, which is what the old hand-built
# apache 2.4.38 package did.
$EnvironmentVariablesEx = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("EnvironmentVariablesEx")
# Installing the VC++ runtime can leave a captured PATH behind. Drop any PATH the capture picked
# up so the entry below is the only one, rather than ending up with two competing PATH nodes.
$EnvironmentVariablesEx.SelectNodes("VariableEx[translate(@name,'PATH','path')='path']") | ForEach-Object { $_.ParentNode.RemoveChild($_) | Out-Null }
AddEnvVar "PATH" "Inherit" "Prepend" ";" "@SYSDRIVE@\Apache24\bin"

################
# Dependencies #
################

# The VC++ runtime is baked in by BuildTurboImage.ps1 because Apache Lounge's VS18 binaries need
# 14.51 and the hub's microsoft/vcredist is still on the VS2022 14.44 runtime. If a matching hub
# release lands, drop the vc_redist download from BuildTurboImage.ps1 and layer it here instead.
# AddDependency "microsoft" "vcredist" "2022" "0000000000000000000000000000000000000000000000000000000000000000" $False

######################
# Edit Startup Files #
######################

# Apache is an extracted .zip rather than an install, so the startup files are set manually.
# httpd is the default: running the image with no tag starts the server in console mode.
$ApacheBin = "@SYSDRIVE@\Apache24\bin"
AddStartupFile "$ApacheBin\httpd.exe"         "httpd"         "" $True  "AnyCpu"
AddStartupFile "$ApacheBin\ApacheMonitor.exe" "apachemonitor" "" $False "AnyCpu"
AddStartupFile "$ApacheBin\ab.exe"            "ab"            "" $False "AnyCpu"
AddStartupFile "$ApacheBin\htpasswd.exe"      "htpasswd"      "" $False "AnyCpu"
AddStartupFile "$ApacheBin\htdigest.exe"      "htdigest"      "" $False "AnyCpu"
AddStartupFile "$ApacheBin\htcacheclean.exe"  "htcacheclean"  "" $False "AnyCpu"
AddStartupFile "$ApacheBin\rotatelogs.exe"    "rotatelogs"    "" $False "AnyCpu"
AddStartupFile "$ApacheBin\openssl.exe"       "openssl"       "" $False "AnyCpu"
