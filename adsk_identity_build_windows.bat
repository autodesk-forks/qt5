@echo off
IF "%~1" == "" GOTO SHOW_USAGE
IF "%~2" == "" GOTO SHOW_USAGE
IF "%~3" == "" GOTO SHOW_USAGE

SET TARGET_PLATFORM=%1
SET BUILD_NUMBER=%2
SET QT_VERSION=%3
echo %TARGET_PLATFORM%
echo %BUILD_NUMBER%
echo %QT_VERSION%

echo ===========================================================================
echo Prepare Visual Studio environment setting
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" %TARGET_PLATFORM%
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Initialise the all submodules repositories
perl ./init-repository -f
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Updating Qt Version
call update_version.bat %QT_VERSION%
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Prepare the workspace path
SET WORKSPACE=%~dp0
SET PATH=%WORKSPACE%\qtbase\bin;%WORKSPACE%\gnuwin32\bin;%PATH%
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Prepare for ICU
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUIN64.dll %~dp0\qtbase\bin 	
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUUC64.dll %~dp0\qtbase\bin 	
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUDT64.dll %~dp0\qtbase\bin 	
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Start building python script
python adsk_identity_build_windows.py
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Copy ICU dlls
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUIN64.dll dist\Qt\5.12.7\bin
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUUC64.dll dist\Qt\5.12.7\bin
copy %EXTERNAL_DIR%\icu\icu_win_release_v140.64.2.0\binary\win_vc14\%TARGET_PLATFORM%\bin\ICUDT64.dll dist\Qt\5.12.7\bin
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Start packaging
cd dist
REM 7z a -t7z %WORKSPACE%\stage\5.12.0-identity-Qt-%BUILD_NUMBER%-win-vc140-10.0.10586.0.7z *
echo Done
echo ===========================================================================
echo.

echo ===========================================================================
echo Restore version changes
git submodule foreach git reset --hard
echo Done
echo ===========================================================================
echo.

goto EOF


:SHOW_USAGE
SET TARGET_PLATFORM=
echo ===========================================================================
echo.
echo  Missing build target TARGET_PLATFORM and build number.
echo    usage: adsk_identity_build_windows.bat {x86 or x64} build_number qt_version
echo    ex; adsk_identity_build_windows.bat x86 00000 5.12.0.0
echo.
echo ===========================================================================

:EOF
