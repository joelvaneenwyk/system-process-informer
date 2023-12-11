@echo off
goto:$Main

:Command
setlocal EnableExtensions EnableDelayedExpansion
    set "_command=%*"
    set "_command=!_command:      = !"
    set "_command=!_command:    = !"
    set "_command=!_command:   = !"
    set "_command=!_command:  = !"
    set _error_value=0
    echo ##[cmd] !_command!
    !_command!
    set _error_value=%ERRORLEVEL%
endlocal & exit /b %_error_value%

:Build
    setlocal EnableExtensions EnableDelayedExpansion
    set _arch=%~1
    set _path=%~2
    set _target=%~3

    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
       set "VSINSTALLPATH=%%a"
    )

    if not defined VSINSTALLPATH (
       echo No Visual Studio installation detected.
       goto:$BuildError
    )

    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$BuildError
    call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" %_arch%

    @cd /d "%~dp0\..\"
    call :Command msbuild /m %_path% -property:Configuration=Debug -property:Platform=%_target% -verbosity:normal
    if errorlevel 1 goto:$BuildError
    call :Command msbuild /m %_path% -property:Configuration=Release -property:Platform=%_target% -verbosity:normal
    if errorlevel 1 goto:$BuildError
    goto:$BuildEnd

    :$BuildError
    echo [ERROR] Build failed: "%_path%"
    goto:$BuildEnd

    :$BuildEnd
endlocal & exit /b %ERRORLEVEL%

:$Main
    setlocal

    call :Build "amd64_x86" "tools\fixlib\fixlib.sln" "x86"
    if errorlevel 1 goto:$MainError

    call :Build "amd64" "tools\GenerateZw\GenerateZw.sln" "Any CPU"
    if errorlevel 1  goto:$MainError
    goto:$MainEnd

    :$MainError
    echo [ERROR] Build failed.
    if not "%SYSTEM_INFORMER_CI%"=="1" (
      pause
    )

    :$MainEnd
endlocal & exit /b %ERRORLEVEL%
