$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

######################
# Edit Startup Files #
######################
# add arguments to the startup file to disable update check and send usage information
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@tag='vlc']").commandLine = '--no-qt-privacy-ask --no-qt-updates-notif'

######################
# Edit Shortcuts #
######################
# add arguments to the shortcuts to disable update check and send usage information
$Shortcuts = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Shortcuts")
$Shortcuts.SelectSingleNode("Folder[@name='Desktop']/Shortcut[@name='VLC media player']").arguments = '--no-qt-privacy-ask --no-qt-updates-notif'
$Shortcuts.SelectSingleNode("Folder[@name='Programs Menu']/Folder[@name='VideoLAN']/Folder[@name='VLC']/Shortcut[@name='VLC media player']").arguments = '--no-qt-privacy-ask --no-qt-updates-notif'