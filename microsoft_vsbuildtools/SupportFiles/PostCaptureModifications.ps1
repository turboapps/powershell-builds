$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
# MSBuild node reuse and the VBCSCompiler/mspdbsrv servers linger after a build; close them when the command prompt exits
$VirtualizationSettings.shutdownProcessTree = [string]$true

# Default install location of the Build Tools instance
$BuildTools = "@PROGRAMFILESX86@\Microsoft Visual Studio\2022\BuildTools"

######################
# Edit Startup Files #
######################
## The capture auto-registers the Visual Studio Installer exes (and the Start Menu "Developer Command Prompt"
## shortcut) as startup files. Disable everything that was captured and register the entry points below instead.
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
foreach ($sf in $StartupFiles.SelectNodes("StartupFile")) {
    $sf.SetAttribute("default", "False")
}

# Default: Developer Command Prompt for VS 2022 - sets PATH/INCLUDE/LIB for MSBuild and the MSVC toolset
AddStartupFile "@SYSTEM@\cmd.exe" "" "/k `"$BuildTools\Common7\Tools\VsDevCmd.bat`"" $True "AnyCpu"

# x64 and x86 Native Tools Command Prompts (triggers: x64, x86)
AddStartupFile "@SYSTEM@\cmd.exe" "x64" "/k `"$BuildTools\VC\Auxiliary\Build\vcvars64.bat`"" $False "AnyCpu"
AddStartupFile "@SYSTEM@\cmd.exe" "x86" "/k `"$BuildTools\VC\Auxiliary\Build\vcvars32.bat`"" $False "AnyCpu"

# Run MSBuild directly (trigger: msbuild)
AddStartupFile "$BuildTools\MSBuild\Current\Bin\MSBuild.exe" "msbuild" "" $False "AnyCpu"

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
