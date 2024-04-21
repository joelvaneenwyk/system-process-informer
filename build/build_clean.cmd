@echo off
goto:$Main

:CustomBuildTool
setlocal EnableExtensions EnableDelayedExpansion
    if "%GITHUB_ACTIONS%"=="" (
        set "_display=##[cmd] "
    ) else (
        set "_display=[command]"
    )
    set _command=start /B /W "" "%~dp0tools\CustomBuildTool\bin\Release\CustomBuildTool.exe"
    echo !_display!!_command!
    cd /d "%~dp0..\"
    call !_command!
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
    call :CustomBuildTool -cleanup
    :$MainDone
        if errorlevel 1 goto:$MainError
        echo [INFO] Build completed successfully.
        goto:$MainEnd

    :$MainError
        echo [ERROR] Build failed. Error level: "%SYSTEM_INFORMER_ERROR_LEVEL%"
        if not "%SYSTEM_INFORMER_CI%"=="1" (
            pause
        )
        goto:$MainEnd

    :$MainEnd
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
