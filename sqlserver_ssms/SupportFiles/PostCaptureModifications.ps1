$PostCaptureFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\!include\PostCaptureFunctions.ps1"
. $PostCaptureFunctionsPath  # Include the script that contains post capture functions

# Configure vm settings
$VirtualizationSettings = $xappl.Configuration.SelectSingleNode("VirtualizationSettings")
$virtualizationSettings.isolateWindowClasses = [string]$true
$virtualizationSettings.launchChildProcsAsUser = [string]$true


######################
# Edit Startup Files #
######################
# Get the path to the Ssms.exe file
$ssmsDir = Get-ChildItem -Path "C:\Program Files (x86)" -Recurse -Filter "Ssms.exe" -ErrorAction SilentlyContinue
$installDir = $ssmsDir.Directory.FullName
$installDir = $installDir -replace [regex]::Escape("${env:ProgramFiles(x86)}"), "@PROGRAMFILESX86@"
$installDir

## Change the container startup file to SSMS.exe
$StartupFiles = $xappl.Configuration.SelectSingleNode("StartupFiles")
$StartupFiles.SelectSingleNode("StartupFile[@node='$installDir\Microsoft.AnalysisServices.Deployment.exe']").default = 'False'
$parentNode = $StartupFiles.SelectNodes("StartupFile[@node='$installDir\Ssms.exe']")
ForEach ($childNodes in $parentNode) {
    $childNodes.SetAttribute("default", "True")
}

