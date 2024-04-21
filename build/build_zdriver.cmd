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
    call !_command!
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:Build
setlocal EnableExtensions
    set "BUILD_SCRIPT=%~nx0"
    set "BUILD_ROOT=%~dp1"
    if "%BUILD_ROOT:~-1%"=="\" set "BUILD_ROOT=%BUILD_ROOT:~0,-1%"
    shift

    set "BUILD_CONFIGURATION=Debug"
    set "BUILD_TARGET=Build"
    set "PREFAST_ANALYSIS="

    :argLoop
    if not "%~1"=="" (
        if "%~1"=="debug" (
            set "BUILD_CONFIGURATION=Debug"
            shift
            goto :argLoop
        )
        if "%~1"=="release" (
            set "BUILD_CONFIGURATION=Release"
            shift
            goto :argLoop
        )
        if "%~1"=="build" (
            set "BUILD_TARGET=Build"
            shift
            goto :argLoop
        )
        if "%~1"=="rebuild" (
            set "BUILD_TARGET=Rebuild"
            shift
            goto :argLoop
        )
        if "%~1"=="clean" (
            set "BUILD_TARGET=Clean"
            shift
            goto :argLoop
        )
        if "%~1"=="prefast" (
            set "PREFAST_ANALYSIS=-p:RunCodeAnalysis=true -p:CodeAnalysisTreatWarningsAsErrors=true"
            shift
            goto :argLoop
        )
        shift
        goto :argLoop
    )

    set "VSINSTALLPATH="
    for /f "usebackq tokens=*" %%A in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VSINSTALLPATH=%%A"
    )
    if not defined VSINSTALLPATH goto:$BuildSetDevEnvError
    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$BuildSetDevEnvError

    :$BuildBuild
        call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64

        echo [+] Building... %BUILD_CONFIGURATION% %BUILD_TARGET% %PREFAST_ANALYSIS% %LEGACY_BUILD%

        set "_msbuild=msbuild "%BUILD_ROOT%\KSystemInformer\KSystemInformer.sln" -restore -t:%BUILD_TARGET% -maxCpuCount -consoleLoggerParameters:Summary;Verbosity=normal"

        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%" -p:Platform="x64" %PREFAST_ANALYSIS%
        if errorlevel 1 goto:$BuildError

        :: #todo Need to re-append %PREFAST_ANALYSIS% after analysis warnings are resolved
        call :Command %_msbuild% -p:Configuration="%BUILD_CONFIGURATION%" -p:Platform="ARM64"
        if errorlevel 1 goto:$BuildError

        echo [+] Build Complete! %BUILD_CONFIGURATION% %BUILD_TARGET% %PREFAST_ANALYSIS% %LEGACY_BUILD%
        goto:$BuildEnd

    :$BuildSetDevEnvError
        echo [-] Failed to set up build environment.
        set "SYSTEM_INFORMER_ERROR_LEVEL=22"
        goto:$BuildError

    :$BuildError
        echo [ERROR] [%BUILD_SCRIPT%] Command failed. [%SYSTEM_INFORMER_ERROR_LEVEL%] %SYSTEM_INFORMER_LAST_COMMAND%
        if not "%SYSTEM_INFORMER_CI%"=="1" pause
        goto:$BuildEnd

    :$BuildEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%SYSTEM_INFORMER_ERROR_LEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%SYSTEM_INFORMER_LAST_COMMAND%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
    call :Build "%~dp0..\" %*
exit /b %errorlevel%
