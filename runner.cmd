@echo off
setlocal enableextensions enabledelayedexpansion
%~dp0runner.exe %*
echo !ERRORLEVEL!>%~dp0tmp/wd2/exitcode
