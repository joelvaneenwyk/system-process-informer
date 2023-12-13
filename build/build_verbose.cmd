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

:SetDevEnv
    for /f "usebackq tokens=*" %%a in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
       set "VSINSTALLPATH=%%a"
    )

    if not defined VSINSTALLPATH (
       echo No Visual Studio installation detected.
       goto:$BuildError
    )

    if not exist "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" goto:$BuildError
    call "%VSINSTALLPATH%\VC\Auxiliary\Build\vcvarsall.bat" %~1
goto:eof

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

:BuildSolution
setlocal EnableDelayedExpansion
    goto:$BuildConfig
    :BuildConfig
    setlocal EnableDelayedExpansion
       set "_solution_path=%~dp1\%~2"
       set "_config=%~3"
       set "_target=%~4"
       set "_msbuild_args=msbuild /m "%_solution_path%" -verbosity:normal -property:Configuration="%_config%" "

       if "%_target%"=="" (
           set "_target=x64"
       )
       call :Command %_msbuild_args% -t:"Restore" -property:Platform="!_target!"
       if errorlevel 1 goto:$BuildConfigDone

       call :Command %_msbuild_args% -property:Platform="!_target!"
       if errorlevel 1 goto:$BuildConfigDone
       if "%~2"=="" goto:$BuildConfigDone

       call :Command %_msbuild_args% -property:Platform="Win32"
       if errorlevel 1 goto:$BuildConfigDone

       call :Command %_msbuild_args% -property:Platform="ARM64"
       if errorlevel 1 goto:$BuildConfigDone

       :$BuildConfigDone
    endlocal & (
        set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
        set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
    )
    exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
    :$BuildConfig

    set "_root=%~dp0..\"
    set "_arch=%~1"
    set "_solution=%~2"
    set "_target=%~3"

    call :SetDevEnv "%_arch%"
    if errorlevel 1 goto:$BuildSolutionDone

    call :BuildConfig "%_root%" "%_solution%" "Debug" "%_target%"
    if errorlevel 1 goto:$BuildSolutionDone

    call :BuildConfig "%_root%" "%_solution%" "Release" "%_target%"
    if errorlevel 1 goto:$BuildSolutionDone

    :$BuildSolutionDone
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%

:$Main
setlocal EnableExtensions
    call :TryRemoveIntermediateFiles

    call :BuildSolution "amd64_arm64" "SystemInformer.sln"
    if errorlevel 1 goto:$MainError

    call :BuildSolution "amd64_arm64" "Plugins\Plugins.sln"
    if errorlevel 1 goto:$MainError

    echo Builds completed successfully!
    goto:$MainEnd

    :$MainError
        echo [ERROR] Build failed. Last command: %SYSTEM_INFORMER_LAST_COMMAND% [Error: %ERRORLEVEL%]
        if "%SYSTEM_INFORMER_CI%"=="1" goto:$MainEnd

        :: If not running a CI build then pause so that user can inspect errors
        pause
:$MainEnd
endlocal & (
    set "SYSTEM_INFORMER_ERROR_LEVEL=%ERRORLEVEL%"
    set "SYSTEM_INFORMER_LAST_COMMAND=%_command%"
)
exit /b %SYSTEM_INFORMER_ERROR_LEVEL%
