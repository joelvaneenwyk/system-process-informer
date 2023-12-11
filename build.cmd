@echo off
goto:$Main

:CommandVar
setlocal EnableDelayedExpansion
    set "_command=!%~1!"
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

:Command
setlocal EnableDelayedExpansion
    set "_command=%*"
    call :CommandVar "_command"
endlocal & exit /b

:$Main
setlocal
    call :Command "%~dp0build\build_thirdparty.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_tools.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_verbose.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_verbose_extras.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_sdk.cmd"
    if errorlevel 1 goto:$MainError

    call :Command "%~dp0build\build_zdriver.cmd"
    if errorlevel 1 goto:$MainError

    echo Builds all completed successfully!
    goto:$MainDone

    :$MainError
    echo [ERROR] Build failed. Error level: '%ERRORLEVEL%'

    :$MainDone
endlocal & exit /b %ERRORLEVEL%
