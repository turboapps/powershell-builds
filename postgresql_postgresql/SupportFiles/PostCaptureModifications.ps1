$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

###################
# Edit Services   #
###################

$Services = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("Services")

# Disable autostart for all services to avoid file lock conflict between startup file and services (APPQ-3726).
ForEach ($Service in $Services.SelectNodes("Service")) {
  $Service.start = "LoadOnDemand"
}

###############################
# Edit Named Object Isolation #
###############################

# Isolate the postgresql basednamedojbect to allow running multiple instances side-by-side (VM-2420).
$NamedObjectIsolation = $xappl.Configuration.SelectSingleNode("NamedObjectIsolation")

$node = $xappl.CreateElement("Exception")
$node.SetAttribute("regex","postgresql")
$NamedObjectIsolation.AppendChild($node)

######################
# Edit Startup Files #
######################
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")

# Uncheck any default startup files
$StartupFiles.SelectSingleNode("StartupFile[@default='True']").default = 'False'

# Add a new startup file for "C:\pgsql\run-postgre-sql.bat"
$node = $xappl.CreateElement("StartupFile")
$node.SetAttribute("node","@SYSDRIVE@\pgsql\run-postgre-sql.bat")
$node.SetAttribute("tag","postgres")
$node.SetAttribute("commandLine","")
$node.SetAttribute("default","True")
$node.SetAttribute("architecture","AnyCpu")
$StartupFiles.AppendChild($node)
