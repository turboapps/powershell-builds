$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################
# add arguments to the startup file to disable update check and send usage information
# Null-guarded: arm64 captures don't always produce the same StartupFiles/Shortcuts trees as x64
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$vlcStartup = $StartupFiles.SelectSingleNode("StartupFile[@tag='vlc']")
if ($vlcStartup) { $vlcStartup.commandLine = '--no-qt-privacy-ask --no-qt-updates-notif' }

######################
# Edit Shortcuts #
######################
# add arguments to the shortcuts to disable update check and send usage information
$Shortcuts = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Shortcuts")
$desktopShortcut = $Shortcuts.SelectSingleNode("Folder[@name='Desktop']/Shortcut[@name='VLC media player']")
if ($desktopShortcut) { $desktopShortcut.arguments = '--no-qt-privacy-ask --no-qt-updates-notif' }
$programsShortcut = $Shortcuts.SelectSingleNode("Folder[@name='Programs Menu']/Folder[@name='VideoLAN']/Folder[@name='VLC']/Shortcut[@name='VLC media player']")
if ($programsShortcut) { $programsShortcut.arguments = '--no-qt-privacy-ask --no-qt-updates-notif' }