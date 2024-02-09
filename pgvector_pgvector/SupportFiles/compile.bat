CALL "c:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

set "PGROOT=C:\pgsql"

cd %USERPROFILE%\Desktop\package\installer\pgvector-master
nmake /F Makefile.win
nmake /F Makefile.win install

xcopy c:\pgsql\include\server\extension\vector %USERPROFILE%\Desktop\package\installer\pgsql\include\extension\vector\
xcopy c:\pgsql\lib\vector.dll %USERPROFILE%\Desktop\package\installer\pgsql\lib\
xcopy c:\pgsql\share\extension\vector*.* %USERPROFILE%\Desktop\package\installer\pgsql\share\extension\

taskkill /F /IM vctip.exe /T
exit