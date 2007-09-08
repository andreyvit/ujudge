@echo off
pushd %~dp1
set srcdir=%CD%
popd
pushd %~dp2
copy %1 .\
%~dp0java1.5.0_01\bin\javac %~nx1
popd
