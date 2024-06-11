$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Filesystem #
###################


## Add the directory path Application Data\Microsoft\Windows\Start Menu\Programs\Startup and set Startup to Full isolation
## This will prevent OneNote from creating a shortcut in the native Startup folder when using Merge isolation
AddDirectory "Directory[@name='@APPDATA@']" "Microsoft" "Merge" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']" "Windows" "Merge" "False" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']" "Start Menu" "Merge" "False" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']/Directory[@name='Start Menu']" "Programs" "Merge" "False" "False" "False"
AddDirectory "Directory[@name='@APPDATA@']/Directory[@name='Microsoft']/Directory[@name='Windows']/Directory[@name='Start Menu']/Directory[@name='Programs']" "Startup" "Full" "False" "False" "False"


######################
# Edit Startup Files #
######################
## Change the container startup file to WINWORD
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='@PROGRAMFILES@\Microsoft Office\Office16\WINWORD.EXE']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}

