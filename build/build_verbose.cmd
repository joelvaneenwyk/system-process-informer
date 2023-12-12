@echo off
goto:$Main

:Command
setlocal EnableExtensions EnableDelayedExpansion
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
endlocal & exit /b %ERRORLEVEL%

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
exit /b

:BuildSolution %arch% %solution% %target%
setlocal
    goto:$BuildConfig
    :BuildConfig
       set "_config=%~1"
       set "_target=%~2"
       set "_msbuild_args=msbuild /m "%_solution%" -verbosity:normal -property:Configuration="%_config%" "

       if "%_target%"=="" goto:$BuildConfigDefault
           call :Command %_msbuild_args% -t:"Restore;Build" -property:Platform="%_target%"
           if errorlevel 1 goto:$BuildConfigDone
       goto:$BuildConfigDone

       :$BuildConfigDefault
           call :Command %_msbuild_args% -property:Platform="Win32"
           if errorlevel 1 goto:$BuildConfigDone

           call :Command %_msbuild_args% -property:Platform="x64"
           if errorlevel 1 goto:$BuildConfigDone

           call :Command %_msbuild_args% -property:Platform="ARM64"
           if errorlevel 1 goto:$BuildConfigDone
       :$BuildConfigDone
    exit /b %ERRORLEVEL%
    :$BuildConfig

    set "_arch=%~1"
    set "_solution=%~2"
    set "_target=%~3"

    call :SetDevEnv "%_arch%"

    cd /d "%~dp0\..\"

    call :BuildConfig "Debug" "%_target%"
    if errorlevel 1 goto:$BuildSolutionDone

    call :BuildConfig "Release" "%_target%"
    if errorlevel 1 goto:$BuildSolutionDone

    :$BuildSolutionDone
endlocal & exit /b %ERRORLEVEL%

:Build
setlocal
    call :BuildSolution "amd64_arm64" "SystemInformer.sln"
    if errorlevel 1 goto:$BuildDone

    call :BuildSolution "amd64_arm64" "Plugins\Plugins.sln"
    if errorlevel 1 goto:$BuildDone

    call :BuildSolution "amd64_x86" "tools\fixlib\fixlib.sln" "x86"
    if errorlevel 1 goto:$BuildDone

    call :BuildSolution "amd64" "tools\GenerateZw\GenerateZw.sln" "Any CPU"
    if errorlevel 1 goto:$BuildDone

    :$BuildDone
endlocal & exit /b %ERRORLEVEL%

:$Main
setlocal EnableExtensions
    call :Build
    if errorlevel 1 goto:$MainError

    echo Builds completed successfully!
    goto:$MainEnd

    :$MainError
    echo [ERROR] Build failed.
    if not "%SYSTEM_INFORMER_CI%"=="1" pause
    goto:$MainEnd

    :$MainEnd
endlocal & exit /b %ERRORLEVEL%
