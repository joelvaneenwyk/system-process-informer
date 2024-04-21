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
    set "SYSTEM_INFORMER_CI=1"
    call !_command!
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:CustomBuildTool
setlocal EnableDelayedExpansion
    set "_tool=%~dp0tools\CustomBuildTool\bin\Release\CustomBuildTool.exe"
    if not exist "!_tool!" call :Command "%~dp0build_tools.cmd"
    if not exist "!_tool!" (
        echo [WARNING] Skipped command due to missing tool: "!_tool!"
        goto:$CustomBuildToolEnd
    )

    cd /d "%~dp0..\"
    call :Command start /B /wait "Custom Build Tool" "!_tool!" %*
    :$CustomBuildToolEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%SYSTEM_INFORMER_ERROR_LEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%SYSTEM_INFORMER_LAST_COMMAND%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
    call :CustomBuildTool -cleanup
    if errorlevel 1 goto:$MainError

    :$MainGitClean
        set "GIT_ASK_YESNO=false"
        call :Command git clean -xfd
        echo [INFO] Build completed successfully.
        goto:$MainEnd

    :$MainError
        echo [ERROR] [%~nx0] Command failed. [%SYSTEM_INFORMER_ERROR_LEVEL%] %SYSTEM_INFORMER_LAST_COMMAND%
        if not "%SYSTEM_INFORMER_CI%"=="1" pause
        goto:$MainEnd

    :$MainEnd
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
