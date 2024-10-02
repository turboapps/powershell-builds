$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true


# Add the folder @APPDATALOCAL@\Temp to fix a permission error when using merge isolation
# Can be removed when bug VM-2490 is resolved
AddDirectory "Directory[@name='@APPDATALOCAL@']" "Temp" "WriteCopy" "False" "False"

# Change folder and subfolders from Merge to WriteCopy isolation
PushFolderIsolation "Directory[@name='@APPDATACOMMON@']/Directory[@name='Adobe']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@PROGRAMFILES@']/Directory[@name='Adobe']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@PROGRAMFILESCOMMON@']/Directory[@name='Adobe']/descendant-or-self::*" "Merge" "WriteCopy"
PushFolderIsolation "Directory[@name='@PROGRAMFILESCOMMONX86@']/Directory[@name='Adobe']/descendant-or-self::*" "Merge" "WriteCopy"