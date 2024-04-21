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

:TryRemoveDirectory
    if not exist "%~1" goto:$TryRemoveDirectoryEnd
    call :Command rmdir /S /Q "%~1"
    if exist "%~1" goto:$TryRemoveDirectoryEnd
    echo Removed directory: '%~1'
    :$TryRemoveDirectoryEnd
exit /b 0

:TryRemoveIntermediateFiles
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-windows-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-windows10.0.22621.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net7.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Debug"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\obj"
exit /b 0

:$Main
setlocal EnableExtensions
    set "ROOT_DIR=%~dp0\..\"
    cd /d "%ROOT_DIR%"

    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
       set "VSINSTALLPATH=%%a"
    )

    if not defined VSINSTALLPATH (
       echo No Visual Studio installation detected.
       goto:$MainError
    )

    if exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" (
       call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" amd64
    ) else (
       goto:$MainError
    )

    :: Pre-cleanup (required since dotnet doesn't cleanup)
    call :TryRemoveIntermediateFiles

    call :Command dotnet publish "%~dp0..\tools\CustomBuildTool\CustomBuildTool.sln" ^
        -c Release ^
        /p:PublishProfile="%~dp0..\tools\CustomBuildTool\Properties\PublishProfiles\64bit.pubxml" ^
        /p:ContinuousIntegrationBuild=true
    if errorlevel 1 goto:$MainError
    goto:$MainEnd

    :$MainError
        echo [ERROR] Build failed for 'CustomBuildTool' project.
        if not "%SYSTEM_INFORMER_CI%"=="1" pause
        goto:$MainEnd

    :$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%SYSTEM_INFORMER_ERROR_LEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%SYSTEM_INFORMER_LAST_COMMAND%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
