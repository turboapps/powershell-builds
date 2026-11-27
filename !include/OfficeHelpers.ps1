# Shared helpers for the Microsoft 365 Apps (Click-to-Run / ODT) builds:
#   microsoft_office-o365proplus-x64, microsoft_office-o365business-x64, microsoft_onenote-x64,
#   microsoft_project-onlinedesktopclient-x64, microsoft_visio-plan2-x64
#
# Why this exists: the configuration.xml files ask for Channel="Current" but carry no Version, so
# ODT is free to pick the build. On the capture runners it has been installing the Semi-Annual
# Enterprise Channel build 16.0.20326.20318 (Version 2608) every night while the Current Channel
# was at 16.0.20625.x. The build read that version back from the registry and pushed it, so each
# night an image older than the one already on the hub was published. These helpers pin ODT to the
# exact Current Channel build the version check found, refuse to capture on top of an existing
# Office install, and refuse to push a build whose installed version is not the one requested.
#
# Dot-source after GlobalBuildScript.ps1 (uses WriteLog, Compare-VersionStrings).

# Latest Current Channel build (eg 16.0.20625.20142) from Microsoft's update history page.
# Returns the full 4-part version; callers that compare against hub tags apply RemoveTrailingZeros.
Function Get-LatestOfficeCurrentChannelVersion {
    # Parsing adapted from https://github.com/DataForNerds/public/blob/main/scripts/ms/msapps/m365buildnumbers.ps1
    $rootPage = "https://learn.microsoft.com/en-us/officeupdates/update-history-microsoft365-apps-by-date"

    $pageData = Invoke-WebRequest $rootPage -UseBasicParsing
    If ($pageData.StatusCode -ne 200) {
        Throw "Error $($pageData.StatusCode) Getting Page Data"
    }

    # Table 1 is the release history by date: Year | Release date | Current | Monthly Enterprise | Semi-Annual ...
    # Rows are newest first, so the first Current Channel link is the latest Current Channel build.
    $tables = [regex]::New('(?msi)<table>(?:.*?)<tbody>(.*?)<\/tbody>').Matches($pageData.Content)
    $rows = [regex]::New('(?msi)<tr>(.*?)<\/tr>').Matches($tables[1].Groups[1].Value)
    $rxCell = [regex]::New('(?msi)<td(?:[^>]*)>(.*?)<\/td>')
    $rxVersionBuild = [regex]::New('(?msi)Version (.*?) \(Build {1,}(.*?)\)')

    foreach ($row in $rows) {
        $cells = $rxCell.Matches($row.Groups[1].Value)
        if ($cells.Count -lt 3) { continue }
        $match = $rxVersionBuild.Match($cells[2].Groups[1].Value)  # Current Channel column
        if ($match.Success) {
            Return "16.0.$($match.Groups[2].Value.Trim())"
        }
    }
    Return $null
}

# Click-to-Run Office already on the machine before capture means ODT modifies that install in
# place (keeping its channel/version) and the capture only records the delta. Fail loudly instead
# of producing a partial image with the wrong version.
Function Assert-NoOfficeInstalled {
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
    if ($c2r) {
        WriteLog "Microsoft 365 Apps are already installed on this machine before capture:"
        WriteLog "  VersionToReport=$($c2r.VersionToReport) Platform=$($c2r.Platform) ProductReleaseIds=$($c2r.ProductReleaseIds)"
        WriteLog "  CDNBaseUrl=$($c2r.CDNBaseUrl) UpdateChannel=$($c2r.UpdateChannel)"
        WriteLog "The capture machine must not have Office installed. Fix the runner image and re-run."
        WriteLog "BuildResult=failed"
        Exit 1
    }
    $policy = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" -ErrorAction SilentlyContinue
    if ($policy) {
        WriteLog "Office update policy present on runner: updatebranch=$($policy.updatebranch) updatetargetversion=$($policy.updatetargetversion)"
    }
}

# Write a copy of the app's ODT configuration pinned to $Version, with a fresh, empty SourcePath so
# neither /download nor /configure can pick up an Office payload left by an earlier run.
# Returns the path of the generated configuration file.
Function New-PinnedOfficeConfig($SourceConfig, $Version, $WorkDir) {
    if ([string]::IsNullOrWhiteSpace($Version)) {
        WriteLog "No Office version to pin to. Exiting."
        WriteLog "BuildResult=failed"
        Exit 1
    }
    $OfficeSource = Join-Path $WorkDir "OfficeSource"
    if (Test-Path $OfficeSource) { Remove-Item $OfficeSource -Recurse -Force }
    New-Item -ItemType Directory -Path $OfficeSource -Force | Out-Null

    [xml]$config = Get-Content -Path $SourceConfig -Raw
    $add = $config.Configuration.Add
    $add.SetAttribute("Version", $Version)
    $add.SetAttribute("SourcePath", $OfficeSource)

    $PinnedConfig = Join-Path $WorkDir "Configuration.pinned.xml"
    $config.Save($PinnedConfig)
    WriteLog "ODT configuration pinned to Channel=$($add.Channel) Version=$Version SourcePath=$OfficeSource"
    Return $PinnedConfig
}

# Fail the build if the installed Office version is not the one that was requested, so an
# unexpected (older, or other-channel) build is never imported or pushed.
Function Assert-OfficeInstalledVersion($Expected, $Installed) {
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
    if ($c2r) {
        WriteLog "ClickToRun VersionToReport=$($c2r.VersionToReport) CDNBaseUrl=$($c2r.CDNBaseUrl)"
    }
    if ([string]::IsNullOrWhiteSpace($Installed) -or (Compare-VersionStrings $Installed $Expected) -ne 0) {
        WriteLog "Installed Office version '$Installed' does not match the requested version '$Expected'. Not pushing. Exiting."
        WriteLog "BuildResult=failed"
        Exit 1
    }
    WriteLog "Installed Office version matches the requested version $Expected."
}
