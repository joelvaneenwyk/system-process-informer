@echo off
goto:$Main

:SetDevEnv
    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
       set "VSINSTALLPATH=%%a"
    )

    if not defined VSINSTALLPATH (
       echo No Visual Studio installation detected.
       goto:$BuildError
    )

    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$BuildError
    call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" %~1
goto:eof

:$Main
setlocal EnableExtensions
    call :SetDevEnv amd64_arm64
    call lib /machine:x86 /def:lib32/bcd.def /out:lib32/bcd.lib
    call "%~dp0../fixlib/bin/Release/fixlib.exe" lib32/bcd.lib
    call lib /machine:x64 /def:lib64/bcd.def /out:lib64/bcd.lib

    pause
endlocal & exit /b %ERRORLEVEL%
