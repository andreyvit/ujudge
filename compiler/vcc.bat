SET PATH=%PATH%;%~dp0vcc\Bin
%~dp0..\..\compiler\vcc\Bin\cl.exe /EHsc /Ox /I%~dp0..\..\compiler\vcc\INCLUDE /Fe%2 %1 /link/LIBPATH:%~dp0..\..\compiler\vcc\LIB
