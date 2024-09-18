CALL "c:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

cd "C:\whisper.cpp-source"
cmake -S . -B .\build
cmake --build .\build --config Release

taskkill /F /IM vctip.exe /T
exit