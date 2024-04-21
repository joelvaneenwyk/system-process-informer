@echo off
goto:$Main

:Command
setlocal EnableDelayedExpansion
    set "_command=%*"
    set "_command=!_command:      = !"
    set "_command=!_command:    = !"
    set "_command=!_command:   = !"
    set "_command=!_command:  = !"
    if "%GITHUB_ACTIONS%"=="" (
        echo ##[cmd] !_command!
    ) else (
        echo [command]!_command!
    )
    !_command!
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
    setlocal EnableExtensions
    cd /d "%~dp0\..\"

    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
       set "VSINSTALLPATH=%%a"
    )

    if not defined VSINSTALLPATH (
       echo No Visual Studio installation detected.
       goto:$MainError
    )

    if exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" (
       call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64
    ) else (
       goto:$MainError
    )

    if exist "tools\thirdparty\bin" (
       rmdir /S /Q "tools\thirdparty\bin"
    )
    if exist "tools\thirdparty\obj" (
       rmdir /S /Q "tools\thirdparty\obj"
    )

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Debug -property:Platform=x86 -verbosity:normal
    if errorlevel 1 goto:$MainError

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Release -property:Platform=x86 -verbosity:normal
    if errorlevel 1 goto:$MainError

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Debug -property:Platform=x64 -verbosity:normal
    if errorlevel 1 goto:$MainError

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Release -property:Platform=x64 -verbosity:normal
    if errorlevel 1 goto:$MainError

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Debug -property:Platform=ARM64 -verbosity:normal
    if errorlevel 1 goto:$MainError

    call :Command msbuild /m tools\thirdparty\thirdparty.sln -property:Configuration=Release -property:Platform=ARM64 -verbosity:normal
    if errorlevel 1 goto:$MainError
    goto:$MainEnd

    :$MainError
        echo [ERROR] Build failed for 'thirdparty' project.
        if not "%SYSTEM_INFORMER_CI%"=="1" pause

    :$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%SYSTEM_INFORMER_LAST_COMMAND%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

