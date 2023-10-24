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

# Download latest installer
Function DownloadInstaller($DownloadLink,$DownloadPath, $InstallerName) {
    # Download installer if it does not already exist
    if (Test-Path -Path $DownloadPath\$InstallerName -PathType Leaf) {
        WriteLog "File already downloaded: $DownloadPath\$InstallerName"
    } else {
        WriteLog "Downloading latest installer to $DownloadPath\$InstallerName"
        wget $DownloadLink -O $DownloadPath\$InstallerName
        Wait-ForFileExistence $DownloadPath\$InstallerName -Iterations 3600 -SleepTime 1  # Exit if file doesn't exist after 60 minutes
    }
    Return "$DownloadPath\$InstallerName"
}

# Start Turbo Capture
Function StartTurboCapture() {
    WriteLog "Starting Turbo Capture."
    $ProcessExitCode = RunProcess $XStudio "/capture start /destination $TurboCaptureDir" $False
    WriteLog "Waiting for Turbo Capture to intialize..."
    Start-Sleep -Seconds 30

}

function RemoveTrailingZeros {
    param (
        [string[]]$version
    )
	
    # Trim spaces from version
    $trimmedVersion = $version.Trim()

    # Split into array of version numbers.
	$verArray = $trimmedVersion.split(".")
	
	# Reverse array to look at trailing zeroes first
	[array]::Reverse($verArray)

	# Find first non-zero index
	$index = 0
    $len = $verArray.length
	ForEach ($v in $verArray[0..$len]) {
	  if ([int]$v -ne 0) {
		$index = $verArray.IndexOf($v)
		break
	  }
	}
	
	# Copy array from first non-zero index to end.
	$verArrayTrimmed = $verArray[$index..($verArray.length)]
	# Reverse back to normal version order
	[array]::Reverse($verArrayTrimmed)
    If ($verArrayTrimmed.Length -eq 1) {
        $verArrayTrimmed = $verArrayTrimmed + "0"
    }
    
	$verTrimmed = $verArrayTrimmed -join "."
    
	return $verTrimmed
}

# Get Current Hub Version of application
Function GetCurrentHubVersion($HubOrg) {
    $HubURL = "https://hub.turbo.net/run/"  # URL used to get the current Hub version
    $HubURL = $HubURL + $HubOrg
    WriteLog "Getting the current version from $HubURL"
    $HubPage = Invoke-WebRequest -Uri ($HubURL) -UseBasicParsing
    $VersionLink = ($HubPage.Links | Where-Object {$_.class -like "*tag-badge ellipsis*"})
    $CurrentHubVersion = $VersionLink.title
    $CurrentHubVersion = RemoveTrailingZeros $CurrentHubVersion
    WriteLog "HubVersion=$CurrentHubVersion"
    Return $CurrentHubVersion
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
         WriteLog "BuildResult=Skipped"
         Exit 0
    }
}

# Use the Windows Installer object to get the ProducVersion property from an unsigned MSI file
Function Get-MsiProductVersion {
    param (
        [Parameter(Mandatory=$True)]
        [string]$MsiPath
    )

    $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $database = $windowsInstaller.OpenDatabase($MsiPath, 0)
    $view = $database.OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'")
    $view.Execute()
    $record = $view.Fetch()
    $msiproductVersion = $record.StringData(1)
    $view.Close()
    Return $msiproductVersion
}

Function GetVersionFromRegistry($AppPartName) {
 # Get the installed version from the 64 bit registry
 $key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
 $subKey = $key.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
 $subKeyNames = $subKey.GetSubKeyNames()
 foreach($name in $subKeyNames) {
     $sub = $subKey.OpenSubKey($name)
     $displayName = $sub.GetValue("DisplayName")
     if($displayName -match "$AppPartName") {
         # Output the key name and display name
         $RegistryVersion = $sub.GetValue("DisplayVersion")
     }
 }

 if ([string]::IsNullOrWhiteSpace($RegistryVersion)) { # Check the 32bit reg keys if no version found
      foreach ($subkey in Get-ChildItem ("HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")) {
        $name = (Get-ItemProperty $subkey.PSPath).DisplayName
        if ($name -match "$AppPartName") {
            $RegistryVersion = (Get-ItemProperty $subkey.PSPath).DisplayVersion
        }
      }
 }

 if ([string]::IsNullOrWhiteSpace($RegistryVersion)) { # Check MSIX apps if no version found
      $RegistryVersion = Get-AppPackage -AllUsers | Where-Object { $_.Name -match "$AppPartName" } | Select-Object Version
      $RegistryVersion = $RegistryVersion.version
 }

 $RegistryVersion = RemoveTrailingZeros $RegistryVersion 
 WriteLog "Registry Display Version: $RegistryVersion"
 Return $RegistryVersion
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
    WriteLog "Importing image: $HubOrg`:$InstalledVersion"
    $ProcessExitCode = RunProcess $Turbo "import svm $SVM --name=$HubOrg`:$InstalledVersion" $True
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
        WriteLog "BuildResult=Success"
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
      WriteLog "BuildResult=Fail"
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

