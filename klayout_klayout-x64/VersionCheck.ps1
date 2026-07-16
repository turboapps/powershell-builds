function RunVersionCheck {
    $LatestWebVersion = $null
    try {
        $downloadPage = "https://www.klayout.de/build.html"
        $downloadHtml = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
        $downloadUrl = $null

        $matches = [regex]::Matches($downloadHtml.Content, 'https://[^"\s<>]+')
        foreach ($match in $matches) {
            $candidate = $match.Value
            if ($candidate -match 'klayout' -and $candidate -match '\.exe$' -and $candidate -match '(?i)(win64|64-bit|64bit|x64)') {
                $downloadUrl = $candidate
                break
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($downloadUrl)) {
            $installerName = [System.IO.Path]::GetFileName($downloadUrl)
            $versionMatch = [regex]::Match($installerName, '(?i)klayout-(\d+\.\d+\.\d+)-')
            if ($versionMatch.Success) {
                $LatestWebVersion = $versionMatch.Groups[1].Value
            }
        }
    } catch {
        WriteLog "Unable to check KLayout version from website: $($_.Exception.Message)"
    }

    if (-not [string]::IsNullOrWhiteSpace($LatestWebVersion)) {
        WriteLog "WebVersion=$LatestWebVersion"
    }
}
