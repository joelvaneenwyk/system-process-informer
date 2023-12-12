@echo off
goto:$Main

:TryRemoveDirectory
    if exist "%~1" (
       echo ##[cmd] rmdir /S /Q "%~1"
       rmdir /S /Q "%~1"
       echo Removed directory: '%~1'
    )
exit /b 0

:TryRemoveIntermediateFiles
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-windows-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net8.0-windows10.0.22621.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Release\net7.0-x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\Debug"
    call :TryRemoveDirectory "tools\CustomBuildTool\bin\x64"
    call :TryRemoveDirectory "tools\CustomBuildTool\obj"
exit /b

:$Main
    setlocal enableextensions
    set "ROOT_DIR=%~dp0\..\"
    cd /d "%ROOT_DIR%"

    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
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

    dotnet publish tools\CustomBuildTool\CustomBuildTool.sln ^
        -c Release ^
        /p:PublishProfile=Properties\PublishProfiles\64bit.pubxml ^
        /p:ContinuousIntegrationBuild=true
    if errorlevel 1 goto:$MainError

    :: Post-cleanup (optional)
    call :TryRemoveIntermediateFiles
    goto:$MainEnd

    :$MainError
    echo [ERROR] Build failed for 'CustomBuildTool' project.
    if not "%SYSTEM_INFORMER_CI%"=="1" pause
:$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
