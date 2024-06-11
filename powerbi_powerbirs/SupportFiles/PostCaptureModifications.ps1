$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$VirtualizationSettings.httpUrlPassthrough = [string]$true
$VirtualizationSettings.chromiumSupport = [string]$true
$virtualizationSettings.isolateWindowClasses = [string]$true
$virtualizationSettings.launchChildProcsAsUser = [string]$true

# Set MachineSid - allows user settings to be portable between devices using the same sandbox
$MachineSid = $xappl.Configuration.SelectSingleNode("Device").SelectSingleNode("MachineSid")
$MachineSid.InnerText = "S-1-5-21-992951991-166803189-1664049914"


###################
# Edit Filesystem #
###################

# Sets Merge isolation on @APPDATALOCAL@\Microsoft\Power BI Desktop SSRS
$Filesystem.SelectSingleNode("Directory[@name='@APPDATALOCAL@']/Directory[@name='Microsoft']/Directory[@name='Power BI Desktop SSRS']").isolation = "Merge"

######################
# Remove EdgeWebView #
######################

#Remove folders @PROGRAMFILESX86@\Microsoft\EdgeUpdate and @PROGRAMFILESX86@\Microsoft\EdgeWebView and @PROGRAMFILESX86@\Microsoft\EdgeCore
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESX86@']/Directory[@name='Microsoft']/Directory[@name='EdgeUpdate']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESX86@']/Directory[@name='Microsoft']/Directory[@name='EdgeWebView']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
$Filesystem.SelectNodes("Directory[@name='@PROGRAMFILESX86@']/Directory[@name='Microsoft']/Directory[@name='EdgeCore']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }


#Remove reg key @HKLM@\SOFTWARE\WOW6432node\Microsoft\EdgeUpdate
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='EdgeUpdate']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
#Remove reg key @HKLM@\SOFTWARE\WOW6432node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Uninstall']/Key[@name='Microsoft EdgeWebView']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }