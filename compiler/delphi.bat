:: @echo off
echo INPUT IS %1, OUTPUT IS %2
:: echo %~dp0delphi7\bin\dcc32 -CC -u%~dp0delphi7\lib -E%~dp2 %1
set src=%1
%~dp0..\..\compiler\delphi7\bin\dcc32 -CC -u%~dp0..\..\compiler\delphi7\lib -E%~dp2 %src:/=\%
set exe=%~dp2%~n1.exe
if exist %exe% copy %exe% %2
