$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


###################
# Edit Filesystem #
###################

# Sets Merge isolation on C:\opensearch\snapshots, so that users can place their backups in that location and load them up
$Filesystem.SelectSingleNode("Directory[@name='@SYSDRIVE@']/Directory[@name='opensearch']/Directory[@name='snapshots']").isolation = "Merge"

