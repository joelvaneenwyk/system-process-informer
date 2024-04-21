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

:$Main
setlocal EnableExtensions
    if exist "%~dp0\output\cab" call :Command rmdir /q /s "%~dp0\output\cab"
    if exist "%~dp0\output\KSystemInformer.cab" call :Command del "%~dp0\output\KSystemInformer.cab"

    call :Command "%~dp0\build_zdriver.cmd" release rebuild
    if errorlevel 1 (
        echo [-] Build failed, CAB was not generated.
        goto:$MainError
    )

    mkdir "%~dp0\output\cab"

    (call :Command robocopy "%~dp0\..\KSystemInformer\bin" "%~dp0\output\cab" *.sys *.dll *.pdb /mir) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if %ERRORLEVEL% neq 0 (
        echo [-] Failed to copy build artifacts to CAB directory.
        goto:$MainError
    )

    (call :Command robocopy "%~dp0\..\KSystemInformer" "%~dp0\output\cab" KSystemInformer.inf) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if %ERRORLEVEL% neq 0 (
        echo [-] Failed to copy INF to CAB directory.
        goto:$MainError
    )

    pushd "%~dp0\output\cab"
    makecab /f "%~dp0\KSystemInformer.ddf"
    if %ERRORLEVEL% neq 0 (
        echo [-] Failed to generate CAB.
        popd
        goto:$MainError
    )
    popd

    (call :Command robocopy "%~dp0\output\cab\disk1" "%~dp0\output" KSystemInformer.cab) ^& if %ERRORLEVEL% lss 8 set ERRORLEVEL = 0
    if %ERRORLEVEL% neq 0 (
        echo [-] Failed to copy CAB to output folder.
        goto:$MainError
    )

    if exist "%~dp0\output\cab" call :Command rmdir /q /s "%~dp0\output\cab"
    echo [+] CAB Complete!

    echo [.] Preparing to sign CAB...

    for /f "usebackq tokens=*" %%A in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set VSINSTALLPATH=%%A
    )

    if not defined VSINSTALLPATH (
        echo [-] Visual Studio not found
        goto:$MainError
    )

    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" (
        echo [-] Failed to set up build environment
        goto:$MainError
    )
    call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64

    echo [.] Signing: "%~dp0\output\KSystemInformer.cab"
    call :Command signtool sign /fd sha256 /n "Winsider" "%~dp0\output\KSystemInformer.cab"
    if errorlevel 1 goto:$MainError

    echo [+] CAB Signed!
    goto:$MainEnd

    :$MainError
        echo [ERROR] Build failed.
        if "%SYSTEM_INFORMER_CI%"=="1" goto:$MainEnd

        :: If not running a CI build then pause so that user can inspect errors
        pause
:$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%SYSTEM_INFORMER_LAST_COMMAND%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
