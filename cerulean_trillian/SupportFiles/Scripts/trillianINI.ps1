# Define the search path
$searchPath = Join-Path $env:APPDATA "trillian\users"

# Find the first instance of trillian.ini, excluding the Global folder
$trillianIniPath = Get-ChildItem -Path $searchPath -Recurse -Filter "trillian.ini" | 
    Where-Object { $_.FullName -notmatch "\\Global\\" } | 
    Select-Object -First 1 -ExpandProperty FullName

if ($trillianIniPath) {
    Write-Host "Found trillian.ini at: $trillianIniPath"

    # Read the content of the file
    $content = Get-Content -Path $trillianIniPath -Raw

    # Perform the replacements
    $content = $content -replace "Server Alerts Minor=.*", "Server Alerts Minor=0"
    $content = $content -replace "Server Alerts Major=.*", "Server Alerts Major=0"
    $content = $content -replace "Check for updates=.*", "Check for updates=0"
    $content = $content -replace "Times Loaded=.*", "Times Loaded=1"
    $content = $content -replace "Time=.*", "Time="

    # Save the modified content back to the file
    $content | Set-Content -Path $trillianIniPath

    Write-Host "Successfully modified trillian.ini"
} else {
    Write-Host "Could not find trillian.ini in the specified path."
}