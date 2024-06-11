$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true

###################
# Edit Filesystem #
###################


## Add the directory path Application Data\Microsoft\Windows\Start Menu\Programs and set folder to Full isolation
## This will prevent an issue with Teams trying to create this .lnk file on launch if the APPDATA folder is redirected to the network and the Programs folder doesn't exist
AddDirectory "Directory[@name='@APPDATA@']" "Microsoft" "WriteCopy" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']" "Windows" "WriteCopy" "False" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']" "Start Menu" "Full" "False" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']/Directory[@name='Start Menu']" "Programs" "Full" "False" "False" "False"

# Clone the Microsoft Teams (work or school).lnk from @PROGRAMS@ to @APPDATA@\Microsoft\Windows\Start Menu\Programs
$fileNode = $xappl.SelectSingleNode("//File[@name='Microsoft Teams (work or school).lnk']").CloneNode($true)
$newFileNode = $fileNode.Clone()
$Filesystem.SelectSingleNode("Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']/Directory[@name='Start Menu']/Directory[@name='Programs']").AppendChild($newFileNode)
