Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################
# Get the directory where the sikuli script is located
$sikuliPath = Join-Path -Path $PSScriptRoot -ChildPath "SupportFiles\Sikulix"

# Set the current working directory to sikuli script folder
Set-Location -Path $sikuliPath

# Pull down the sikulix and openjdk turbo images from turbo.net hub if they are not already part of the image
$turboArgs = "config --domain=turbo.net"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
$turboArgs = "pull sikulix/sikulixide,microsoft/openjdk"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True

# Launch SikulixIDE to get the latest version from Adobe Admin Console
$turboArgs = "try sikulixide --using=microsoft/openjdk --offline --disable=spawnvm --isolate=merge-user --startup-file=java -- -jar @SYSDRIVE@\SikulixIDE\sikulixide-2.0.5.jar -r $sikuliPath\version.sikuli -f $env:userprofile\desktop\version-sikulix-log.txt"
$ProcessExitCode = RunProcess "turbo.exe" $turboArgs $True
CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on install error

# Read the contents of the version.txt file into $LatestWebVersion
$LatestWebVersion = Get-Content -Path "$env:userprofile\desktop\version.txt" -Raw

$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
