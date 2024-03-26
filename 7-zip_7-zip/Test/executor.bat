@echo off

rem The image to be tested.
set "image=7-zip/7-zip"

rem The isolation setting for the app.
set "isolation=merge-user"

rem The other images used (in this test, no other image is used).
rem set "using=<using>"

rem Install the app to be tested.
call %~dp0\..\..\_INCLUDE\Test\install.bat %image% %isolation%

rem Start `turbo try` command for the test.
call %~dp0\..\..\_INCLUDE\Test\try.bat %image% %isolation%

rem Run the SikuliX test script for the app.
call %~dp0\..\..\_INCLUDE\Test\test.bat %image%