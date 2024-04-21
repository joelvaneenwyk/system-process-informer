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

:CustomBuildTool
exit /b

:$Main
setlocal EnableExtensions
    set "ROOT_DIR=%~dp0\..\"
    cd /d "%ROOT_DIR%"
    @cd /d "%~dp0\..\"

    start /B /W "" "tools\CustomBuildTool\bin\Release\CustomBuildTool.exe" "-cleanup"
    if errorlevel 1 goto:$Error
    echo [INFO] Build completed successfully.
    goto:$MainEnd

    :$Error
        echo [ERROR] Build failed.
        if not "%SYSTEM_INFORMER_CI%"=="1" pause
:$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
