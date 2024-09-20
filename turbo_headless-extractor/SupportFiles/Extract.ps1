# Script for extracting content from a web page at a URL

# If updating this script, change the version number in SupportFiles\version.txt

param (
    [Parameter(Mandatory=$true)]
    [string]$Url,

    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    
    [Parameter(Mandatory=$false)]
    [string]$Timeout,
    
    [Parameter(Mandatory=$false)]
    [switch]$DOM,
    
    [Parameter(Mandatory=$false)]
    [switch]$Screenshot,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExtractLinks,

    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",

    [int]$WindowHeight = 5000,

    [int]$WindowWidth = 1920
)

function MakeAbsoluteUrl {
    param (
        [System.Uri]$BaseUri,
        [string]$RelativeUrl
    )

    try {
        return [System.Uri]::new($BaseUri, $RelativeUrl).AbsoluteUri
    }
    catch {
        # If we can't create a valid absolute URL, return the relative url
        return $RelativeUrl
    }
}

function ExtractLinks {
    param (
        [string]$HtmlFilePath,
        [string]$BaseUrl
    )
    
    $doc = New-Object HtmlAgilityPack.HtmlDocument
    $doc.Load($HtmlFilePath)

    $baseUri = New-Object System.Uri($BaseUrl)
    $linkNodes = $doc.DocumentNode.SelectNodes("//a[@href]")

    if ($null -eq $linkNodes) {
        return @()
    }

    $links = $linkNodes | 
        ForEach-Object { $_.GetAttributeValue("href", "") } | 
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { MakeAbsoluteUrl -BaseUri $baseUri -RelativeUrl $_ } |
        Where-Object { $null -ne $_ } |
        Sort-Object |
        Get-Unique

    return $links
}

# Ensure output directory exists
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Build command
$requestTimeout = "300000" # Default timeout for Chrome is 5 minutes
if ($Timeout)
{
    $requestTimeout = $Timeout
}
$command = "`"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`" --headless=new --user-agent=`"$UserAgent`" --dump-dom --window-size=$WindowWidth,$WindowHeight --virtual-time-budget=10000 --timeout=$requestTimeout --no-sandbox --disable-extensions --disable-gpu --disable-gpu-sandbox --temp-profile"
Write-Host $command
if ($Screenshot)
{
    # Only take screenshot if option specified in parameter
    $imagePath = Join-Path $OutputDir "image.png"
    $command += " --screenshot=$imagePath"
}
$command += " $Url"

try {
    # Start the process and capture output
    $output = cmd /c $command

    # Load the HTML Agility Pack
    Add-Type -Path "C:\extractor\HtmlAgilityPack.dll"

    # Get the text from the raw html
    $doc = New-Object HtmlAgilityPack.HtmlDocument
    $doc.LoadHtml($output)
    $htmlText = $doc.DocumentNode.InnerText.Trim()
    $htmlText = $htmlText -replace "\s+", " "
    
    # Write the output to a text file
    $domTextOutputFile = Join-Path $OutputDir "domText.txt"
    $htmlText | Out-File -FilePath $domTextOutputFile -Encoding utf8
    
    Write-Host "DOM text output saved to: $domTextOutputFile"
    
    if ($DOM)
    {
        # Write the raw DOM output to dom.html
        $domOutputFile = Join-Path $OutputDir "dom.html"
        $output | Out-File -FilePath $domOutputFile -Encoding utf8
    
        Write-Host "DOM output saved to: $domOutputFile"
    }
    
    if ($Screenshot)
    {
        # Screenshot is specified in command line option earlier so if param was passed notify caller here
        Write-Host "Screenshot saved to: $imagePath"
    }

    # Only extract links if option specified in parameter
    if ($ExtractLinks)
    {
        # Parse the DOM and extract links
        $links = ExtractLinks -HtmlFilePath $domOutputFile -BaseUrl $Url

        # Write links to a file
        $linksOutputFile = Join-Path $OutputDir "links.txt"
        $links | Out-File -FilePath $linksOutputFile -Encoding utf8

        Write-Host "Absolute links extracted and saved to: $linksOutputFile"
    }
}
catch {
    Write-Host "An error occurred: $_"
}
