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
$XStudio = Get-ChildItem -Path "C:\Program Files (x86)\Turbo.net" -Recurse -Filter "XStudio.exe" -File | Select-Object -ExpandProperty FullName  
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

# Get current Hub revisions of application
Function GetHubRevisions($HubOrg,$URL) {
    if (!$URL) {
        $URL = $PushURL
    }
    # Split the repo parts into owner and name values
    $repoOwner, $repoName = $HubOrg -split "_"
    WriteLog "Getting the current $HubOrg version from $URL"
    
    # Get token from API Key
    $headers = @{}
    $headers.Add("X-Turbo-Api-Key", $APIKey)
    $reqUrl = $URL + '/0.1/api-keys/login'
    $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers  

    # Get all repos from Hub
    $headers = @{}
    $headers.Add("X-Turbo-Ticket", $response)
    $headers.Add("X-Turbo-Api-Id", "turbo.net")
    $headers.Add("X-Turbo-Api-Version", "1")

    # Get the revisions array for the repo
    $reqUrl = $URL + '/io/_hub/repo/' + $repoOwner + '/' + $repoName + '/revisions?withTags'
    $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers
    Return $response
}

# Get Current Hub Version of application
Function GetCurrentHubVersion($HubOrg,$URL) {
    $response = GetHubRevisions $HubOrg $URL

    # Get the first imageID from the repo
    if ($response.imageid.count -gt 1) {
        $imageID = $response.imageID[0]
        }
    else {
        $imageID = $response.imageID
    }

    # Get all the versions from the first image
    $Objects = $response | Where-Object {$_.imageID -eq $imageID}
    $CurrentHubVersion = $Objects.tags
    
    If ($CurrentHubVersion.Count -gt 1) { # If there are more than 1 version for the latest image get the first one with a decimal
        $LatestHubVer = $CurrentHubVersion | Where-Object {$_ -match '\.'} | Select-Object -First 1 # Select first version with a decimal
        }
    Else {  # If there is only 1 version set as the latest
        $LatestHubVer = $CurrentHubVersion
    }

    $LatestHubVer = RemoveTrailingZeros $LatestHubVer
    WriteLog "HubVersion=$LatestHubVer"

    Return $LatestHubVer
}

# Get the current Hub hash of the application
Function GetCurrentHubHash($HubOrg,$URL) {
    $response = GetHubRevisions $HubOrg $URL

    # Get the first imageID from the repo (this is the hash)
    if ($response.imageid.count -gt 1) {
        $imageID = $response.imageID[0]
        }
    else {
        $imageID = $response.imageID
    }

    Return $imageID
}

Function CheckHubVersion() {
    If ([string]::IsNullOrWhiteSpace($PushURL)) {
         WriteLog "No PushURL parameter. Proceeding to download installer."
    } else {
         $VersionScriptPath = Join-Path -Path $scriptPath -ChildPath "VersionCheck.ps1"  #Get the path to the VersionCheck.ps1
         If (Test-Path -Path $VersionScriptPath) {
             . $VersionScriptPath  # Include the script that compares the Hub version to the latest web version
             WriteLog "VersionCheck script found.  Comparing Hub version to Web version."
             RunVersionCheck
         } else {
             WriteLog "No VersionCheck script. Proceeding to download installer."
         }
     }
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

# Check if any given process name is running
Function CheckRunningProcess($processName) {
    # Check if the process is running
    if (Get-Process -ProcessName $processName -ErrorAction SilentlyContinue) {
        WriteLog "$processName is running."
        Return 1
    } else {
        WriteLog "$processName is not running."
        Return 0
    }
}

# Start Turbo Capture
Function StartTurboCapture() {
    WriteLog "Starting Turbo Capture."
    $ProcessExitCode = RunProcess "cmd.exe" "/C `"$XStudio`" /capture start /destination $TurboCaptureDir" $False
    WriteLog "Waiting for Turbo Capture to start..."
    Start-Sleep -Seconds 10
    # run xstudio /capture query until it returns a 0 meaning the capture is fully initialized.
    $attempts = 0
    $maxAttempts = 5
    $captureStarted = 1  # Initialize to a non-zero value to enter the loop

    Do {
        WriteLog "Waiting for Turbo Capture to initialize (Attempt $($attempts + 1)/$maxAttempts)..."
        $captureStarted = RunProcess "cmd.exe" "/C `"$XStudio`" /capture query" $True
        Start-Sleep -Seconds 2
        $attempts++
    } While ($captureStarted -ne 0 -and $attempts -lt $maxAttempts)

    if ($captureStarted -ne 0) {
        WriteLog "Failed to initialize Turbo Capture after $maxAttempts attempts."
        exit 1  # Exit with a failure code
    }

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

# Get the latest version from Turbo.net hub
Function GetTurboNetHubVersion($HubOrg) {
    $HubURL = "https://hub.turbo.net/run/"  # URL used to get the current Hub version
    $HubURL = $HubURL + $HubOrg
    WriteLog "Getting the current version from $HubURL"
    $HubPage = Invoke-WebRequest -Uri ($HubURL) -UseBasicParsing
    $VersionLink = ($HubPage.Links | Where-Object {$_.class -like "*tag-badge ellipsis*"})
    $CurrentHubVersion = $VersionLink.title
    $CurrentHubVersion = RemoveTrailingZeros $CurrentHubVersion
    #If the hub version is comma separated, use the last version
    if ($CurrentHubVersion -like "*,*") {
        # Split the variable by the comma delimiter
        $splitArray = $CurrentHubVersion -split ','

        # Set the variable to the last value in the array
        $CurrentHubVersion = $splitArray[-1]
    }

    WriteLog "HubVersion=$CurrentHubVersion"
    Return $CurrentHubVersion
}

# Compare the current Turbo Hub Version to the latest available download version.
# Exits the script if Hub is the same or newer.
function Compare-Versions($Version1, $Version2) {
    WriteLog "Comparing Current Turbo Hub version to Latest available version."
    If ($Version1 -eq $null -or $Version1 -eq ".0") {
         WriteLog "Failed to get Hub Version. Exiting."
         WriteLog "BuildResult=failed"
         Exit 0
    }
    If ($Version2 -eq $null -or $Version2 -eq ".0") {
         WriteLog "Failed to get Web Version. Exiting."
         WriteLog "BuildResult=failed"
         Exit 0
    } 
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

# Get the version from the EXE file from the VersionInfo.ProductVersion property
Function Get-VersionFromExe {
    param (
        [Parameter(Mandatory=$True)]
        [string]$ExePath
    )
    $ExeFile = Get-Item "$ExePath"
    $exeproductVersion = $ExeFile.VersionInfo.ProductVersion
    
    Return $exeproductVersion
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
    Wait-ForFileExistence $XapplPath -Iterations 7200 -SleepTime 1  # Exit if file doesn't exist after 120 minutes
    WriteLog "Waiting for Turbo Capture to finalize..."
    DO {         
        $XStudioRunning = CheckRunningProcess "xstudio"
        Start-Sleep -Seconds 10
        } While ($XStudioRunning -ne 0)
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
    $ProcessExitCode = RunProcess $XStudio "$FinalXapplPath /o $SVM /l `"$TurboLicense`"" $True
    CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo capture failure
    WriteLog "Waiting for .svm file to be created..."
    Wait-ForFileExistence $SVM -Iterations 3600 -SleepTime 1   # Exit if file doesn't exist after 60 minutes
    WriteLog "BuildResult=Success"
        
}

# Imports the image, and pushes to the Turbo Hub
Function PushImage($PushVersion) {
    WriteLog "Import parameter = $Import"
    If ($Import -eq $true) {
        WriteLog "Importing image: $HubOrg`:$PushVersion"
        WriteLog "Push URL parameter = $PushURL"
        WriteLog "ApiKey parameter = $ApiKey"
        $ProcessExitCode = RunProcess $Turbo "import svm $SVM --name=$HubOrg`:$PushVersion" $True
        CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo import failure
       # $ProcessExitCode = RunProcess $Turbo "check $HubOrg" $True
       # CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo check failure

        If ($PushURL -like 'http*') {
            WriteLog "Pushing image to Turbo Server: $PushURL"
            $ProcessExitCode = RunProcess $Turbo "config --domain=$PushURL" $True
            CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo config failure
            $ProcessExitCode = RunProcess $Turbo "login --api-key $ApiKey" $True
            CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo login failure
            $ProcessExitCode = RunProcess $Turbo "push $HubOrg`:$PushVersion $HubOrg`:$PushVersion" $True
            CheckForError "Checking process exit code:" 0 $ProcessExitCode $True # Fail on turbo login failure
            WriteLog "PushResult=Success"
        }
    } else {
        WriteLog "PushResult=Skipped"
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

# Uses headless Edge to get the user-agent string for the headless browser
Function EdgeGetUserAgentString([String]$headlessMode) {
    $browser = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $arguments =  "--headless=$headlessMode --temp-profile --disable-gpu --dump-dom --virtual-time-budget=10000 $BuildScriptPath\HelperFiles\get-user-agent.html"
    
    # Create a temporary file to capture the output
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    $process = Start-Process -FilePath $browser -ArgumentList $arguments -NoNewWindow -RedirectStandardOutput $tempFile -PassThru

        # Wait for the process to exit
        $process.WaitForExit()

        # Read the content from the temporary file
        $content = Get-Content -Path $tempFile -Raw       
        $userAgent = [regex]::Match($content, '(?<=<p id="uastring">).+?(?=</p>)').Value
        $userAgent = $userAgent -replace 'Headless',''  # Remove 'Headless' from the userAgent

        # Clean up the temporary file
        Remove-Item -Path $tempFile

        # Return the content
        return $userAgent
}


# Uses headless Edge to scrape the contents of a web page including JavaScript created content
Function EdgeGetContent([String]$url,[String]$headlessMode) {
    $userAgent = EdgeGetUserAgentString -headlessMode "old"
    $browser = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $arguments =  "--headless=$headlessMode --temp-profile --disable-gpu --dump-dom --virtual-time-budget=10000 --user-agent=`"$userAgent`" $url"
    
    # Create a temporary file to capture the output
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    $process = Start-Process -FilePath $browser -ArgumentList $arguments -NoNewWindow -RedirectStandardOutput $tempFile -PassThru

        # Wait for the process to exit
        $process.WaitForExit()

        # Read the content from the temporary file
        $content = Get-Content -Path $tempFile -Raw

        # Clean up the temporary file
        Remove-Item -Path $tempFile

        # Return the content
        return $content
}
