@echo off

SET CUR_TEST=test-1s

SET UTILS_PATH=Z:\zx\!work\!utils
SET UNREAL_PATH=Z:\zx\pc\emuls\us\unreal.exe
SET UNREAL_DIR=Z:\zx\pc\emuls\us\

del /q test*.sna

%UTILS_PATH%\sjasmplus.exe sources\test-1s.asm
%UTILS_PATH%\sjasmplus.exe sources\test-1s-attr.asm
%UTILS_PATH%\sjasmplus.exe sources\test-2s.asm
%UTILS_PATH%\sjasmplus.exe sources\test-2s-attr.asm

IF NOT EXIST %CUR_TEST%.sna GOTO ERROR

GOTO END

:ERROR
EXIT 1

:END