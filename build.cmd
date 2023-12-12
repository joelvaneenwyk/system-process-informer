@echo off
goto:$Main

:ClearError
exit /b 0

:Command
setlocal EnableExtensions EnableDelayedExpansion
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
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
    exit /b %ERRORLEVEL%
)

:$Main
setlocal EnableExtensions EnableDelayedExpansion
    call :ClearError

    set SYSTEM_INFORMER_CI=1

    call :Command "%~dp0build\build_thirdparty.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_tools.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_verbose.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_sdk.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_zdriver.cmd" debug
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_zdriver.cmd" release
    if errorlevel 1 goto:$MainError

    echo Builds all completed successfully!
    goto:$MainDone

    :$MainError
    echo [ERROR] Build failed. Last command: "!SYSTEM_INFORMER_LAST_COMMAND!" [Error: %ERRORLEVEL%]

    :$MainDone
endlocal & exit /b %ERRORLEVEL%
