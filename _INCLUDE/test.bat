@echo off
rem Run the SikuliX test for the app.
rem Usage: test.bat <image>

rem Get a formatted prefix for the test log.
for /f "tokens=1,2 delims=/" %%a in ("%1") do (
    set "name=%%a_%%b"
)

rem Run a SikuliX container which run the test.
turbo run sikulixide --using=microsoft/openjdk --offline --disable=spawnvm --isolate=merge-user --startup-file=java -- -jar @SYSDRIVE@\SikulixIDE\sikulixide-2.0.5.jar -r "%~dp0\..\%name%\test.sikuli" -f "%USERPROFILE%\Desktop\%name%-log.txt"

goto :EOF