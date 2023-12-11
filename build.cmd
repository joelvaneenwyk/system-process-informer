@echo off
goto:$Main

:ClearError
exit /b 0

:Command
setlocal EnableDelayedExpansion
    set "_command=%*"
    set "_command=!_command:      = !"
    set "_command=!_command:    = !"
    set "_command=!_command:   = !"
    set "_command=!_command:  = !"
    set _error_value=0

    :$RunCommand
    set SYSTEM_INFORMER_CI=1
    echo ##[cmd] !_command!
    call !_command!
    set _error_value=%ERRORLEVEL%
endlocal & exit /b %_error_value%

:$Main
setlocal EnableExtensions
    call :ClearError

    call :Command "%~dp0build\build_thirdparty.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_tools.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_verbose.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_sdk.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_zdriver.cmd" prefast debug
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_zdriver.cmd" prefast release
    if errorlevel 1 goto:$MainError

    echo Builds all completed successfully!
    goto:$MainDone

    :$MainError
    echo [ERROR] Build failed. Error level: '%ERRORLEVEL%'

    :$MainDone
endlocal & exit /b %ERRORLEVEL%
