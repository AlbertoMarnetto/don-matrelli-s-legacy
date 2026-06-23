@echo off

if not exist GPEGA.EXE echo GPEGA.EXE not found!
if not exist GPEGA.EXE goto :end

if "%1x"=="x" dml /ikwid /t /c /o
if not "%1x"=="x" dml /ikwid %1 %2 %3

gpega

echo Thanks for playing Don Matrelli's Legacy!

:end
