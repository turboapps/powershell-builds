#######################
## General Variables ##
#######################
$BuildScriptPath = $PSScriptRoot # The folder path the script was launched from
$ProgressPreference = 'SilentlyContinue'  # This speeds up the download of the installer files
$LogTimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$packagePath = New-Item -Path "$env:USERPROFILE\Desktop" -Name "Package" -ItemType "directory" -Force  # create a Package folder on the Desktop
$LogPath = New-Item -Path $packagePath -Name "Log" -ItemType "directory" -Force  #  create a Log folder in the Package folder
$LogFile = "$LogPath\log-$LogTimeStamp.log"  # Set path of log file
$NewLine = "`r`n"  #  Adds a blank line to the Log file
$DownloadPath = New-Item -Path $packagePath -Name "Installer" -ItemType "directory" -Force # create an Installer directory in the Desktop Package folder
#$HubOrg = (Split-Path -Path (Get-Location) -Leaf) -replace '_', '/' # Set the repo name based on the folder path of the script assuming the folder is vendor_appname

#####################
## Turbo Variables ##
#####################
if (Test-Path "C:\Program Files (x86)\Turbo.net\Turbo Studio 23\XStudio.exe") { 
    $XStudio = "C:\Program Files (x86)\Turbo.net\Turbo Studio 23\XStudio.exe"  
} else { $XStudio = "C:\Program Files (x86)\Turbo.net\Turbo Studio 22\XStudio.exe" } # The path to XStudio.exe
$Turbo = "C:\Program Files (x86)\Turbo\Cmd\turbo.exe" # The path to Turbo.exe
$TurboCaptureDir = "$packagePath\TurboCapture"  # The folder that the Turbo capture will be saved to
$XapplPath = "$TurboCaptureDir\Capture.xappl"  #  Path to the captured XAPPL file
$SVM = "$TurboCaptureDir\build.svm"  # Path to the Turbo SVM build
$TurboLicense = "$BuildScriptPath\License.txt"  # Path to the Turbo Studio license file
$FinalXapplPath = "$TurboCaptureDir\FinalCapture.xappl"  #  XAPPL with any modifications applied



###############
## Functions ##
###############

# WriteLog - writes string message parameter to log file and console.
Function WriteLog([String]$message) {
    Write-Host "$message"
    $timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
    ("$timestamp $message").replace($NewLine,"") | Out-File -FilePath $LogFile -Append # Strip new lines from message then output to log
}


# Compare the current Turbo Hub Version to the latest available download version.
# Exits the script if Hub is the same or newer.
function Compare-Versions($Version1, $Version2) {
    WriteLog "Comparing Current Turbo Hub version to Latest available version."
    If ([Version]$Version1 -lt [Version]$Version2) {
         WriteLog "A newer version is available."
         Return 1
    } Else {
         WriteLog "Turbo Hub version is the same or newer. Exiting."
         Exit 0
    }
}

# Download latest installer
Function DownloadInstaller($DownloadLink,$DownloadPath, $InstallerName) {
    # Download installer
    WriteLog "Downloading latest installer to $DownloadPath\$InstallerName"
    wget $DownloadLink -O $DownloadPath\$InstallerName
    Wait-ForFileExistence $DownloadPath\$InstallerName -Iterations 3600 -SleepTime 1  # Exit if file doesn't exist after 60 minutes
    Return "$DownloadPath\$InstallerName"
}

# Start Turbo Capture
Function StartTurboCapture() {
    WriteLog "Starting Turbo Capture."
    $ProcessExitCode = RunProcess $XStudio "/capture start /destination $TurboCaptureDir" $False
    WriteLog "Waiting for Turbo Capture to intialize..."
    Start-Sleep -Seconds 30

}

# Stop Turbo Capture
Function StopTurboCapture() {
    WriteLog "Stopping Turbo Capture."
    $ProcessExitCode = RunProcess $XStudio "/capture stop" $True
    CheckForError "Checking process exit code:" 0 $ProcessExitCode  # Fail on turbo capture failure
    WriteLog "Waiting for .xappl file to be created..."
    Wait-ForFileExistence $XapplPath -Iterations 3600 -SleepTime 1  # Exit if file doesn't exist after 60 minutes
    Start-Sleep -Seconds 10
}

# Apply Customizations from a helper script to the XAPPL
Function CustomizeTurboXappl($PostCaptureModificationsPath) {
    WriteLog "Applying post-capture modifications using: $PostCaptureModificationsPath"
    # Load snapshot xappl
    $Xappl = New-Object XML
    $Xappl.Load($XapplPath)
    # Run post snap modifications script
    $result = . $PostCaptureModificationsPath *>&1 # Pipe all output to success stream
    # Print Errors
    WriteLog "Errors found while applying post-capture modifications: $NewLine"
    $result | ForEach-Object { If ($_.GetType().Name -eq 'ErrorRecord') {WriteLog "$($_.Exception)"; WriteLog "$($_.InvocationInfo.ScriptName)"; WriteLog "$($_.InvocationInfo.Line)"}} # Print details for each error found
    # Save XAPPL
    $xappl.Save($FinalXapplPath)
    WriteLog "Processed output configuration: $FinalXapplPath. $NewLine"
}

## Build SVM image
Function BuildTurboSvmImage() {

    WriteLog "Building Turbo SVM Image."
    $ProcessExitCode = RunProcess $XStudio "$FinalXapplPath /o $SVM /l $TurboLicense" $True
    CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo capture failure
    WriteLog "Waiting for .svm file to be created..."
    Wait-ForFileExistence $SVM -Iterations 3600 -SleepTime 1   # Exit if file doesn't exist after 60 minutes

    WriteLog "Import parameter = $Import"
    WriteLog "Push URL parameter = $PushURL"
    WriteLog "ApiKey parameter = $ApiKey"

    If ($Import -eq $true) {TurboPublish}
        
}

# Imports the image, checks the launch and publishes to the Turbo Hub
Function TurboPublish() {
    WriteLog "Importing image: $HubOrg"
    $ProcessExitCode = RunProcess $Turbo "import svm $SVM --name=$HubOrg" $True
    CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo import failure
   # $ProcessExitCode = RunProcess $Turbo "check $HubOrg" $True
   # CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo check failure

    If ($PushURL -like 'http*') {
        WriteLog "Pushing image to Turbo Server: $PushURL"
        $ProcessExitCode = RunProcess $Turbo "config --domain=$PushURL" $True
        CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo config failure
        $ProcessExitCode = RunProcess $Turbo "login --api-key $ApiKey" $True
        CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo login failure
        $ProcessExitCode = RunProcess $Turbo "push $HubOrg $HubOrg`:$InstalledVersion" $True
        CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo login failure
    }
}


# Wait for the provided file to exist and exit if not created in a certain time interval
function Wait-ForFileExistence {
  param (
    [string]$FileExPath,
    [int]$Iterations,
    [int]$SleepTime
  )
  for ($i = 0; $i -lt $Iterations; $i++) {
    if (Test-Path $FileExPath) {
      WriteLog "File exists: $FileExPath"
      return
    }
    Start-Sleep -Seconds $SleepTime
  }
  WriteLog "File does not exist after $Iterations iterations: $FileExPath - Exiting."
  Exit
}

# RunProcess - start process
# - FilePath = string path to process executable
# - arguments = argument string to pass to process
# - ShouldWait = boolean: True = waits until process exits | False = returns to execution after starting process
# Returns process exit code if ShouldWait = true
Function RunProcess([String]$EXEPath,[String]$arguments,[Bool]$ShouldWait) {
  WriteLog "$($NewLine)Executing: $EXEPath $arguments"
  $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
  $ProcessInfo.FileName = $EXEPath
  $ProcessInfo.Arguments = $arguments
  $Process = New-Object System.Diagnostics.Process
  $Process.StartInfo = $ProcessInfo
  $Process.Start() | Out-Null # Pipe out the "True" message, so that only process exit code is returned
  If ($ShouldWait) {
    WriteLog "Waiting for process to finish..."
    $Process.WaitForExit()
    WriteLog "Process finished with exit code $($Process.ExitCode)"
    Return $Process.ExitCode
  }
}

# CheckForError - prints message, result, and expected value.
# Continues script if result = expected value OR $ShouldTerminate = false.
# Stops script with error if result != expected value AND $ShouldTerminate = true.
Function CheckForError($ErrMessage, $ExpectedValue, $ResultValue, $ShouldTerminate) {
  If ($ResultValue -eq $ExpectedValue) {
    WriteLog "Success: $ErrMessage"
    WriteLog "Success: Expected ($ExpectedValue) = Result ($ResultValue) $NewLine"
  }
  Else {
    If ($ShouldTerminate) {
      WriteLog "Error: $ErrMessage"
      WriteLog "Error: Expected ($ExpectedValue) != Result ($ResultValue)"
      WriteLog "Error: Script failed! $NewLine"
      Exit $ResultValue
    }
    Else {
      WriteLog "Warning: $ErrMessage"
      WriteLog "Warning: Expected ($ExpectedValue) != Result ($ResultValue)"
      WriteLog "Warning: Continuing script. $NewLine"
      $global:ScriptError = 0 # Reset script error level if this is a warning
    }
  }
}
