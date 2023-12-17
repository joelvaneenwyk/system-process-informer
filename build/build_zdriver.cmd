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
    set "BUILD_CONFIGURATION=Debug"
    set "BUILD_TARGET=Build"
    set "BUILD_ROOT=%~dp0\..\"
    set "PREFAST_ANALYSIS="

    :argLoop
    if not "%1"=="" (
        if "%1"=="debug" (
            set BUILD_CONFIGURATION=Debug
            shift
            goto :argLoop
        )
        if "%1"=="release" (
            set BUILD_CONFIGURATION=Release
            shift
            goto :argLoop
        )
        if "%1"=="build" (
            set BUILD_TARGET=Build
            shift
            goto :argLoop
        )
        if "%1"=="rebuild" (
            set BUILD_TARGET=Rebuild
            shift
            goto :argLoop
        )
        if "%1"=="clean" (
            set BUILD_TARGET=Clean
            shift
            goto :argLoop
        )
        if "%1"=="prefast" (
            set PREFAST_ANALYSIS=-p:RunCodeAnalysis=true -p:CodeAnalysisTreatWarningsAsErrors=true
            shift
            goto :argLoop
        )
        shift
        goto :argLoop
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

        set "_msbuild=msbuild "%BUILD_ROOT%\KSystemInformer\KSystemInformer.sln" -restore -t:%BUILD_TARGET% -maxCpuCount -consoleLoggerParameters:Summary;Verbosity=minimal"

        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%";Platform=x64 %PREFAST_ANALYSIS%
        if errorlevel 1 goto:$MainError

        :: #todo Need to re-append %PREFAST_ANALYSIS% after analysis warnings are resolved
        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%";Platform=ARM64
        if errorlevel 1 goto:$MainError

        echo [+] Build Complete! %BUILD_CONFIGURATION% %BUILD_TARGET% %PREFAST_ANALYSIS% %LEGACY_BUILD%
        goto:$MainEnd

    :$MainSetDevEnvError
        echo [-] Failed to set up build environment
        goto:$MainError

    :$MainError
        echo [ERROR] Build failed. Last command: %SYSTEM_INFORMER_LAST_COMMAND% [Error: %ERRORLEVEL%]
        if "%SYSTEM_INFORMER_CI%"=="1" goto:$MainEnd

        :: If not running a CI build then pause so that user can inspect errors
        pause
:$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
