@echo off
setlocal enableextensions enabledelayedexpansion
%*
echo !ERRORLEVEL!>%~dp0tmp/wd2/exitcode
