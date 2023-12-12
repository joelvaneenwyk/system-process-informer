@echo off
goto:$Main

:TryRemoveDirectory
    if exist "%~1" (
       echo rmdir /S /Q "%~1"
       rmdir /S /Q "%~1"
    )
exit /b 0

:$Main
@setlocal enableextensions
set "ROOT_DIR=%~dp0\..\"
@cd /d "%ROOT_DIR%"

for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
   set "VSINSTALLPATH=%%a"
)

if not defined VSINSTALLPATH (
   echo No Visual Studio installation detected.
   goto end
)

if exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" (
   call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64
) else (
   goto end
)

:: Pre-cleanup (required since dotnet doesn't cleanup)
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-x64"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net7.0-x64"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Debug"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\x64"
call :TryRemoveDirectory "tools\CustomBuildTool\obj"

dotnet publish tools\CustomBuildTool\CustomBuildTool.sln ^
    -c Release ^
    /p:PublishProfile=Properties\PublishProfiles\64bit.pubxml ^
    /p:ContinuousIntegrationBuild=true

:: Post-cleanup (optional)
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-x64"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net7.0-x64"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\Debug"
call :TryRemoveDirectory "tools\CustomBuildTool\bin\x64"
call :TryRemoveDirectory "tools\CustomBuildTool\obj"
goto:eof

:end
echo [ERROR] Build failed.
if not "%SYSTEM_INFORMER_CI%"=="1" pause
