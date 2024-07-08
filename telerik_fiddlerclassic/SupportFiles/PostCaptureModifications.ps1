$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Clone the IconResource from the "Fiddler Classic" shortcut to the IconResource node for the image meta
# Select the shortcut node and get the <IconResource> node to be cloned from it
$shortcutNode = $xappl.SelectSingleNode("//Shortcut[@name='Fiddler Classic']")
$iconResourceNode = $shortcutNode.SelectSingleNode("IconResource")

# Clone the <IconResource> node
$clonedIconResourceNode = $iconResourceNode.Clone()

# Insert the cloned node to the main configuration node
# This will set the meta icon for the image
$xappl.Configuration.AppendChild($clonedIconResourceNode)
