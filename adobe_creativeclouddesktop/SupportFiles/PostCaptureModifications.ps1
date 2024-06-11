$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.chromiumSupport = [string]$true
$VirtualizationSettings.shutdownProcessTree = [string]$true

###################
# Edit Filesystem #
###################


## Remove script log file directory
$Filesystem.SelectNodes("Directory[@name='@DESKTOP@']/Directory[@name='Package']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

## Remove @PROGRAMFILESCOMMONX86@\Adobe\AdobeGCClient directory
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESCOMMONX86@']/Directory[@name='Adobe']/Directory[@name='AdobeGCClient']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
## Remove @PROGRAMFILESCOMMONX86@\Adobe\Adobe Desktop Common\AdobeGenuineClient directory
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESCOMMONX86@']/Directory[@name='Adobe']/Directory[@name='Adobe Desktop Common']/Directory[@name='AdobeGenuineClient']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }


#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


# Delete registry keys @HKLM@\SOFTWARE\Adobe\Adobe Genuine Service
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Adobe']/Key[@name='Adobe Genuine Service']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

# Delete registry keys @HKCU@\SOFTWARE\RegisteredApplications
$Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='RegisteredApplications']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }

# Delete registry keys @HKLM@\System\CurrentControlSet\Services
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SYSTEM']/Key[@name='CurrentControlSet']/Key[@name='Services']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }


######################
# Edit Startup Files #
######################

# Remove auto-start flag from all
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@default='True']").default = 'False'