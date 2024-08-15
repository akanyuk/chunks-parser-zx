#! /bin/sh

rm -f test*.sna

sjasmplus sources/test-1s.asm
sjasmplus sources/test-1s-attr.asm
sjasmplus sources/test-2s.asm
sjasmplus sources/test-2s-attr.asm
