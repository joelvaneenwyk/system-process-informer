@echo off
setlocal enableextensions
setlocal EnableExtensions
    cd /d "%~dp0\..\"

    start /B /W "" "tools\CustomBuildTool\bin\Release\CustomBuildTool.exe" "-cleansdk"
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
