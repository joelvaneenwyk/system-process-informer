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

:Run
setlocal EnableDelayedExpansion
    call :Command "%~1"
endlocal & exit /b

:$Main
setlocal
    call :Run "%~dp0build\build_thirdparty.cmd"
    call :Run "%~dp0build\build_sdk.cmd"
    call :Run "%~dp0build\build_verbose.cmd"
    call :Run "%~dp0build\build_tools.cmd"
    call :Run "%~dp0build\build_zdriver.cmd"
endlocal
