@echo off
rem Pull the Turbo images and install the app.
rem Usage: install.bat <image> <isolation>[ <using>]

rem Get the API key and domain of Turbo server from secrets.txt. The secret file should locate in the same folder of this batch file.
set "secretsFile=%~dp0\secrets.txt"
for /f "usebackq tokens=1,2 delims=," %%a in ("%secretsFile%") do (
    if "%%a"=="APIKey" (
        set "apiKey=%%b"
    )
    if "%%a"=="Domain" (
        set "domain=%%b"
    )
)

rem Point to the specified Turbo server and log in.
turbo config --domain=%domain%
turbo login --api-key=%apiKey%

rem Stop all Turbo containers.
turbo stop -a

rem Remove all Turbo containers.
turbo rm -a

rem Uninstall all the apps installed by Turbo.
turbo uninstalli -a

rem Pull Turbo images to be installed and used.
turbo pull %1
for /f "tokens=1 delims=," %%a in ("%3") do (
    for /f "delims=" %%b in ("%%a") do (
        turbo pull %%b
    )
)

rem Install the app.
turbo installi %1 --isolate=%2 --using=%3

goto :EOF