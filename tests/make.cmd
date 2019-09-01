@echo off

del /q test*.sna

sjasmplus.exe sources\test-1s.asm
sjasmplus.exe sources\test-1s-attr.asm
sjasmplus.exe sources\test-2s.asm
sjasmplus.exe sources\test-2s-attr.asm
