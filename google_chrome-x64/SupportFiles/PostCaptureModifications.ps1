$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions


# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$virtualizationSettings.isolateWindowClasses = [string]$true

# Set MachineSid - allows Chrome user settings to be portable between devices using the same sandbox
$MachineSid = $xappl.Configuration.SelectSingleNode("Device").SelectSingleNode("MachineSid")
$MachineSid.InnerText = "S-1-5-21-992951991-166803189-1664049914"

# Edit ObjectMaps - Isolating this message window allows multiple Chrome instances to run side-by-side.
$ObjectMaps = $xappl.Configuration.Layers.SelectSingleNode("Layer[@name='Default']").SelectSingleNode("ObjectMaps")
$node = $xappl.CreateElement("ObjectMap")
$node.SetAttribute("value","window://Chrome_MessageWindow:0")
$ObjectMaps.AppendChild($node)


###################
# Edit Filesystem #
###################


# Set the noSync attribute on the LOCALAPPDATA\Google and subfolders
$parentNode = $Filesystem.SelectNodes("Directory[@name='@APPDATALOCAL@']/Directory[@name='Google']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("noSync", "False")
}

# Sets Isolation on the folders
$Filesystem.SelectSingleNode("Directory[@name='@APPDATALOCAL@']/Directory[@name='Google']").isolation = "Full"
$Filesystem.SelectSingleNode("Directory[@name='@PROGRAMFILESX86@']/Directory[@name='Google']").isolation = "Full"
$Filesystem.SelectSingleNode("Directory[@name='@PROGRAMFILES@']/Directory[@name='Google']").isolation = "Full"

#################
# Edit Registry #
#################
## NOTE: Beware of case sensitivity when making registry changes.  eg. The registry value type "String" requires an upper-case 'S'
##       When specifying a registry value, "OpenWithProgids" is different from "OpenWithProgIds"


# Set Full isolation on HKCU\SOFTWARE\Google and subkeys
$userGoogleKey = $Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']")
if (-not $userGoogleKey) {
    AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']" "Google" "Full" "False" "False"
}
$parentNode = $Registry.SelectNodes("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}
# Set Full isolation on HKLM\SOFTWARE\WOW6432Node\Google and subkeys
$parentNode = $Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='WOW6432Node']/Key[@name='Google']/descendant-or-self::*")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("isolation", "Full")
}

# set net.spoon.chromenativehost key to merge isolation, so Turbo VM Extension is able to establish connection with a message host installed natively
$userChromeKey = $Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']/Key[@name='Chrome']")
if (-not $userChromeKey) {
    AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']" "Chrome" "Full" "False" "False"
}
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']/Key[@name='Chrome']" "NativeMessagingHosts" "Full" "False" "False"
AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Google']/Key[@name='Chrome']/Key[@name='NativeMessagingHosts']" "net.spoon.chromenativehost" "Merge" "False" "False"

# Delete registry keys - unnecessary keys
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Active Setup']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }
$Registry.SelectNodes("Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='MediaPlayer']") | ForEach-Object { $_.ParentNode.RemoveChild($_) }


# Add reg key HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall and set to Full Isolation
# This will prevent Chrome Apps from creating Programs and Features entries
$uninstallNode = $Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Uninstall']")
if (-not $uninstallNode) {
    AddRegKey "Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']" "Uninstall" "Full" "False" "False"
}
$Registry.SelectSingleNode("Key[@name='@HKCU@']/Key[@name='SOFTWARE']/Key[@name='Microsoft']/Key[@name='Windows']/Key[@name='CurrentVersion']/Key[@name='Uninstall']").isolation = "Full"

# This will add the ProgIDs for HTTP and HTTPS allowing users to set Chrome as the default browser
# Create Classes reg keys for http and https
AddRegKey "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Classes']" "http" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Classes']/Key[@name='http']" "URL Protocol" "Full" "False" "False" "String" ""
AddRegKey "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Classes']" "https" "Full" "False" "False"
AddRegValue "Key[@name='@HKLM@']/Key[@name='SOFTWARE']/Key[@name='Classes']/Key[@name='https']" "URL Protocol" "Full" "False" "False" "String" ""
# Clone the ChromeHTML ProgID node to http and https
$chromeHtmlNode = $xappl.SelectSingleNode("//ProgId[@name='ChromeHTML']").CloneNode($true)
# Modify the ProgId name and description for HTTP and HTTPS
$httpNode = $chromeHtmlNode.Clone()
$httpNode.SetAttribute("name", "http")
$httpNode.SetAttribute("description", "URL:HyperText Transfer Protocol")
$httpsNode = $chromeHtmlNode.Clone()
$httpsNode.SetAttribute("name", "https")
$httpsNode.SetAttribute("description", "URL:HyperText Transfer Protocol with Privacy")
# Append HTTP and HTTPS ProgIds to the XML structure
$xappl.SelectSingleNode("//ProgIds").AppendChild($httpNode)
$xappl.SelectSingleNode("//ProgIds").AppendChild($httpsNode)
# Clone the OPEN verb to TURBOCLIENT_v24.2_LEGACY_PROGID for http and https ProgIDs
$ProgIDNode = $xappl.SelectSingleNode("//ProgId[@name='http']")
$openVerbNode = $ProgIDNode.SelectSingleNode(".//Verb[@name='open']")
$newVerbNode = $openVerbNode.Clone()
$newVerbNode.SetAttribute("name", "TURBOCLIENT_v24.2_LEGACY_PROGID")
$ProgIDNode.AppendChild($newVerbNode)
$ProgIDNode = $xappl.SelectSingleNode("//ProgId[@name='https']")
$openVerbNode = $ProgIDNode.SelectSingleNode(".//Verb[@name='open']")
$newVerbNode = $openVerbNode.Clone()
$newVerbNode.SetAttribute("name", "TURBOCLIENT_v24.2_LEGACY_PROGID")
$ProgIDNode.AppendChild($newVerbNode)