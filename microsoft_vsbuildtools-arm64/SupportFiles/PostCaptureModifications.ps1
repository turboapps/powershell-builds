$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
# MSBuild node reuse and the VBCSCompiler/mspdbsrv servers linger after a build; close them when the command prompt exits
$VirtualizationSettings.shutdownProcessTree = [string]$true

# Default install location of the Build Tools instance (Program Files (x86) on ARM64 Windows as well)
$BuildTools = "@PROGRAMFILESX86@\Microsoft Visual Studio\2022\BuildTools"
$BuildToolsReal = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"  # Real path on the capture machine, used for existence checks

######################
# Edit Startup Files #
######################
## The capture auto-registers the Visual Studio Installer exes (and the Start Menu "Developer Command Prompt" /
## "ARM64 Native Tools Command Prompt" shortcuts) as startup files. Disable everything that was captured and register the entry points below instead.
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
foreach ($sf in $StartupFiles.SelectNodes("StartupFile")) {
    $sf.SetAttribute("default", "False")
}

# Default: Developer Command Prompt for VS 2022 targeting ARM64 from an ARM64 host - sets PATH/INCLUDE/LIB for MSBuild and the MSVC toolset.
# VsDevCmd.bat defaults to -arch=x86 -host_arch=x86, so the ARM64 architecture is passed explicitly.
AddStartupFile "@SYSTEM@\cmd.exe" "" "/k `"$BuildTools\Common7\Tools\VsDevCmd.bat`" -arch=arm64 -host_arch=arm64" $True "AnyCpu"

# ARM64 Native Tools Command Prompt (trigger: arm64) - same command line as the Start Menu shortcut the VS Installer creates
AddStartupFile "@SYSTEM@\cmd.exe" "arm64" "/k `"$BuildTools\VC\Auxiliary\Build\vcvarsall.bat`" arm64" $False "AnyCpu"

# Run MSBuild directly (trigger: msbuild). Prefer the native ARM64 MSBuild when the installer laid it down.
$MSBuild = "$BuildTools\MSBuild\Current\Bin\MSBuild.exe"
if (Test-Path "$BuildToolsReal\MSBuild\Current\Bin\arm64\MSBuild.exe") {
    $MSBuild = "$BuildTools\MSBuild\Current\Bin\arm64\MSBuild.exe"
}
AddStartupFile "$MSBuild" "msbuild" "" $False "AnyCpu"

# vswhere for locating the toolset from scripts (trigger: vswhere)
AddStartupFile "@PROGRAMFILESX86@\Microsoft Visual Studio\Installer\vswhere.exe" "vswhere" "" $False "AnyCpu"

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'

# Set WriteCopy isolation on @HKCU@\Software\Microsoft\VisualStudio and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='Software']/Key[@name='Microsoft']/Key[@name='VisualStudio']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "WriteCopy")
}

#################
# Edit Files    #
#################
# Change per-user folders and subfolders from Merge to WriteCopy isolation so runtime writes stay in the sandbox
PushFolderIsolation "Directory[@name='@APPDATALOCAL@']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@APPDATA@']/descendant-or-self::*" "Merge" "WriteCopy"
