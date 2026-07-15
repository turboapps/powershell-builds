function RunVersionCheck {
    $LatestWebVersion = $null
    try {
        $downloadPage = "https://www.klayout.de/build.html"
        $downloadHtml = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
        $versionMatches = [regex]::Matches($downloadHtml.Content, '(?i)\b0\.\d+\.\d+\b')
        if ($versionMatches.Count -gt 0) {
            $LatestWebVersion = $versionMatches[0].Value
        }
    } catch {
        WriteLog "Unable to check KLayout version from website: $($_.Exception.Message)"
    }

    if (-not [string]::IsNullOrWhiteSpace($LatestWebVersion)) {
        WriteLog "WebVersion=$LatestWebVersion"
    }
}
