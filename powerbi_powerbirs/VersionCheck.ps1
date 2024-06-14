Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

$DownloadPath = "$env:USERPROFILE\Downloads"
$DesktopPath = "$env:USERPROFILE\Desktop"
$sikulixPath = "$DesktopPath\sikulix"
$IncludePath = Join-Path -Path $scriptPath -ChildPath "..\!include"

# Copy the sikulix resources folder to the desktop
Remove-Item -Path "$DesktopPath\Sikulix" -Recurse -Force
Copy-Item "$SupportFiles\Sikulix" -Destination $DesktopPath -Recurse -Force

# Wait for the warm up of the VM
Start-Sleep -Seconds 30

# Pull down the sikulix and openjdk turbo images from turbo.net hub if they are not already part of the image
$turboArgs = "config --domain=turbo.net"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
$turboArgs = "pull sikulix/sikulixide,microsoft/openjdk"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True

# Launch SikulixIDE to get the latest version
$turboArgs = "try sikulixide --using=microsoft/openjdk --offline --disable=spawnvm --isolate=merge-user --startup-file=java -- -jar @SYSDRIVE@\SikulixIDE\sikulixide-2.0.5.jar -r $sikulixPath\build.sikuli -f $env:userprofile\desktop\build-sikulix-log.txt"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Name of the downloaded installer file
$InstallerName = "PBIDesktopSetupRS_x64.exe"
$Installer = "$DownloadPath\$InstallerName"

$LatestWebVersion = Get-VersionFromExe "$Installer"
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}