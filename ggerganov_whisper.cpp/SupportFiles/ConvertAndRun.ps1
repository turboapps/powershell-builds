# This script will need ffmpeg to be accessible and in system PATH env var to function correctly

# Define some paths
$whisperCmd = "C:\whisper.cpp\main.exe"
$convertedFilePath = "C:\whisper.cpp\tempfile.wav"

# Look through all the command line args to whisper.cpp  
for ($i = 0; $i -lt $args.count; $i++)
{
    if ($args[$i] -eq "-f")
    {
        # Convert input file to proper format
        $whisperCmd += " " + $args[$i]
        $i++
        if ($i -ne $args.count)
        {
            # Convert the input file to 16-bit .wav
            ffmpeg -i $args[$i] -ar 16000 -ac 1 -c:a pcm_s16le $convertedFilePath
            $whisperCmd += " `"$convertedFilePath`""
        }
    }
    elseif ($args[$i] -eq "-of")
    {
        # Output file won't exist but it should still get quoted
        $whisperCmd += " " + $args[$i]
        $i++
        if ($i -ne $args.count)
        {
            $whisperCmd += " `"" + $args[$i] + "`""
        }
    }
    else
    {
        # Non-input file args just get copied to final command verbatim
        if (Test-Path $args[$i])
        {
            # Put quotes around existing valid paths
            $whisperCmd += " `"" + $args[$i] + "`""
        }
        else
        {
            $whisperCmd += " " + $args[$i]
        }
    }
}
Write-Host "Running command: $whisperCmd"

# Run whisper
Invoke-Expression $whisperCmd

# Remove the temporary input file
Remove-Item $convertedFilePath