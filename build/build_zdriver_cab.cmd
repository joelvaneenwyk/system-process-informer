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
    set "_root=%~dp1"
    if "%_root:~-1%"=="\" set "_root=%_root:~0,-1%"
    set "_project_dir=%_root%\KSystemInformer"
    set "_output=%_root%\KSystemInformer\output"

    if exist "%_output%\cab" call :Command rmdir /q /s "%_output%\cab"
    if exist "%_output%\KSystemInformer.cab" call :Command del "%_output%\KSystemInformer.cab"

    :: We set 'SYSTEM_INFORMER_CI' to prevent it from calling 'pause' when it fails.
    set "SYSTEM_INFORMER_CI=1"
    call :Command "%_root%\build\build_zdriver.cmd" release rebuild
    if errorlevel 1 (
        echo [-] Build failed, CAB was not generated.
        goto:$BuildError
    )

    if not exist "%_output%\cab" call :Command mkdir "%_output%\cab"

    (call :Command robocopy "%_root%\KSystemInformer\bin" "%_output%\cab" *.sys *.dll *.pdb /mir) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if errorlevel 1 (
        echo [-] Failed to copy build artifacts to CAB directory.
        goto:$BuildError
    )

    (call :Command robocopy "%_root%\KSystemInformer" "%_output%\cab" KSystemInformer.inf) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if errorlevel 1 (
        echo [-] Failed to copy INF to CAB directory.
        goto:$BuildError
    )

    pushd "%_output%\cab"
    call :Command makecab /f "%_root%\build\KSystemInformer.ddf"
    if errorlevel 1 (
        echo [-] Failed to generate CAB.
        popd
        goto:$BuildError
    )
    popd

    (call :Command robocopy "%_output%\cab\disk1" "%_output%" KSystemInformer.cab) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if errorlevel 1 (
        echo [-] Failed to copy CAB to output folder.
        goto:$BuildError
    )

    if exist "%_output%\cab" call :Command rmdir /q /s "%_output%\cab"
    echo [+] CAB Complete!

    echo [.] Preparing to sign CAB...

    for /f "usebackq tokens=*" %%A in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set VSINSTALLPATH=%%A
    )

    if not defined VSINSTALLPATH goto:$BuildSetDevEnvError
    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$BuildSetDevEnvError

    :$BuildBuild
        call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64

        echo [.] Signing: "%_output%\KSystemInformer.cab"
        call :Command signtool sign /fd sha256 /n "Winsider" "%_output%\KSystemInformer.cab"
        if errorlevel 1 goto:$BuildError

        echo [+] CAB Signed!
        goto:$BuildEnd

    :$BuildSetDevEnvError
        echo [-] Failed to set up build environment.
        if errorlevel 1 (
            set "SYSTEM_INFORMER_ERROR_LEVEL=%errorlevel%"
        ) else (
            set "SYSTEM_INFORMER_ERROR_LEVEL=22"
        )
        goto:$BuildError

    :$BuildError
        echo [ERROR] [%BUILD_SCRIPT%] Build failed. [%SYSTEM_INFORMER_ERROR_LEVEL%] %SYSTEM_INFORMER_LAST_COMMAND%
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
exit /b %ERRORLEVEL%
