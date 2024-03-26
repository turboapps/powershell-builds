@echo off
rem Test `turbo run` command of the app (image). `turbo try` is essentially the same as `turbo run`, and is used here to simplify the test.
rem Usage: try.bat <image> <isolation>[ <using>]

rem Run a temporary container of an image.
turbo try %1 --isolate=%2 --using=%3 --name="test" -d

goto :EOF