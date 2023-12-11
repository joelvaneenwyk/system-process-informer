@echo off
@setlocal enableextensions
@cd /d "%~dp0\..\"

start /B /W "" "tools\CustomBuildTool\bin\Release\CustomBuildTool.exe" "-debug"
if errorlevel 1 goto:$Error
echo [INFO] Build completed successfully.
goto:eof

:$Error
echo [ERROR] Build failed.
if not "%SYSTEM_INFORMER_CI%"=="1" pause

