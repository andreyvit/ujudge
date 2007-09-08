@echo on
SET PATH=%PATH%;%~dp0pp\bin\win32
set ASW=%~dp0pp\bin\win32
set PPC=%~dp0pp\bin\win32
ppc386 -Fu%~dp0pp\units\win32\rtl -Fi%~dp0pp\units\win32\rtl -I%~dp0pp\units\win32\rtl %1
set exe=%~dpn1.exe
if exist %exe% copy %exe% %2
