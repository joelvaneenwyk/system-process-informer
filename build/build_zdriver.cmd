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

:$Main
setlocal EnableExtensions
    set BUILD_CONFIGURATION=Debug
    set BUILD_TARGET=Build
    set PREFAST_ANALYSIS=

    :argloop
    if not "%1"=="" (
        if "%1"=="debug" (
            set BUILD_CONFIGURATION=Debug
            shift
            goto :argloop
        )
        if "%1"=="release" (
            set BUILD_CONFIGURATION=Release
            shift
            goto :argloop
        )
        if "%1"=="build" (
            set BUILD_TARGET=Build
            shift
            goto :argloop
        )
        if "%1"=="rebuild" (
            set BUILD_TARGET=Rebuild
            shift
            goto :argloop
        )
        if "%1"=="clean" (
            set BUILD_TARGET=Clean
            shift
            goto :argloop
        )
        if "%1"=="prefast" (
            set PREFAST_ANALYSIS=-p:RunCodeAnalysis=true -p:CodeAnalysisTreatWarningsAsErrors=true
            shift
            goto :argloop
        )
        shift
        goto :argloop
    )

    for /f "usebackq tokens=*" %%A in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VSINSTALLPATH=%%A"
    )

    if not defined VSINSTALLPATH (
        echo [-] Visual Studio not found
        goto:$MainEnd
    )

    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$MainSetDevEnvError
    :$MainBuild
        call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64

        echo [+] Building... %BUILD_CONFIGURATION% %BUILD_TARGET% %PREFAST_ANALYSIS% %LEGACY_BUILD%

        set "_msbuild=msbuild "%~dp0KSystemInformer\KSystemInformer.sln" -restore -t:%BUILD_TARGET% -maxCpuCount -consoleLoggerParameters:Summary;Verbosity=minimal"

        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%";Platform=x64 %PREFAST_ANALYSIS%
        if errorlevel 1 goto:$MainError

        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%";Platform=ARM64 %PREFAST_ANALYSIS%
        if errorlevel 1 goto:$MainError

        echo [+] Build Complete! %BUILD_CONFIGURATION% %BUILD_TARGET% %PREFAST_ANALYSIS% %LEGACY_BUILD%
        goto:$MainEnd

    :$MainSetDevEnvError
        echo [-] Failed to set up build environment
        goto:$MainError

    :$MainError
        echo [ERROR] Build failed.
        if "%SYSTEM_INFORMER_CI%"=="1" goto:$MainEnd

        :: If not running a CI build then pause so that user can inspect errors
        pause
:$MainEnd
endlocal & exit /b %ERRORLEVEL%
