$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


# Remove the reg key HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate if captured to prevent discrepancies with the version of WebView2 between the capture device and client device.
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Microsoft']/Key[@name='EdgeUpdate']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
