@echo off
@setlocal enableextensions
@cd /d "%~dp0\..\"

start /B /W "" "tools\CustomBuildTool\bin\Release\CustomBuildTool.exe" "-debug"
if "%ERRORLEVEL%"=="0" goto:eof

echo [ERROR] Build failed.
if not "%SYSTEM_INFORMER_CI%"=="1" pause

