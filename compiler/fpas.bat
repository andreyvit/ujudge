@echo on
SET PATH=%PATH%;%~dp0..\..\compiler\pp\bin\win32
set ASW=%~dp0..\..\compiler\pp\bin\win32
set PPC=%~dp0..\..\compiler\pp\bin\win32
ppc386 -Fu%~dp0..\..\compiler\pp\units\win32\rtl -Fi%~dp0..\..\compiler\pp\units\win32\rtl -I%~dp0..\..\compiler\pp\units\win32\rtl %1
set exe=%~dpn1.exe
if exist %exe% copy %exe% %2
