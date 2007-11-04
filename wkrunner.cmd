@echo off
setlocal enableextensions enabledelayedexpansion
%~dp0winkill27.exe %*
echo !ERRORLEVEL!>%~dp0tmp/wd2/exitcode
