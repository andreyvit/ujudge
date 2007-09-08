SET PATH=%PATH%;%~dp0vcc\Bin
%~dp0vcc\Bin\cl.exe /EHsc /I%~dp0vcc\INCLUDE /Fe%2 %1 /link/LIBPATH:%~dp0vcc\LIB
