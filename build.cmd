@echo off
goto:$Main

:Command
setlocal EnableDelayedExpansion
    set "_command=%*"
    if "%GITHUB_ACTIONS%"=="" (
        echo ##[cmd] !_command!
    ) else (
        echo [command]!_command!
    )
    set SYSTEM_INFORMER_CI=1
    call !_command!
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
setlocal EnableExtensions
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
    echo [ERROR] Build failed with '%ERRORLEVEL%' return code. Last command: "%SYSTEM_INFORMER_LAST_COMMAND%" [Error: %ERRORLEVEL%]

    :$MainDone
endlocal & exit /b %ERRORLEVEL%
