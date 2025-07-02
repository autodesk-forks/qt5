@echo off
@rem #################################################
@rem @file VerifyNoGPL.bat
@rem @brief Verification script to ensure no GPL binaries are present
@rem @team FARA/CM (Consistent Material scrum team)
@rem #################################################

set QT_INSTALL_PATH=C:\out
set GPL_COMPONENTS_FOUND=0

echo.
echo #################################################
echo Verifying Qt installation contains no GPL components...
echo Installation path: %QT_INSTALL_PATH%
echo #################################################
echo.

@rem Check for GPL DLLs
echo Checking for GPL DLLs...
if exist "%QT_INSTALL_PATH%\bin\Qt6VirtualKeyboard*.dll" (
    echo ERROR: VirtualKeyboard DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6Charts*.dll" (
    echo ERROR: Charts DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6DataVisualization*.dll" (
    echo ERROR: DataVisualization DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6Quick3D*.dll" (
    echo ERROR: Quick3D DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6Designer*.dll" (
    echo ERROR: Designer DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6Coap*.dll" (
    echo ERROR: Coap DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\bin\Qt6Mqtt*.dll" (
    echo ERROR: Mqtt DLL found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)

@rem Check for GPL QML modules
echo Checking for GPL QML modules...
if exist "%QT_INSTALL_PATH%\qml\QtQuick\VirtualKeyboard" (
    echo ERROR: VirtualKeyboard QML found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\qml\QtCharts" (
    echo ERROR: Charts QML found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\qml\QtDataVisualization" (
    echo ERROR: DataVisualization QML found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\qml\QtQuick3D" (
    echo ERROR: Quick3D QML found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\qml\Qt\labs\lottieqt" (
    echo ERROR: Lottie QML found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)

@rem Check for GPL libraries
echo Checking for GPL libraries...
if exist "%QT_INSTALL_PATH%\lib\Qt6VirtualKeyboard*" (
    echo ERROR: VirtualKeyboard library found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\lib\Qt6Charts*" (
    echo ERROR: Charts library found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\lib\Qt6DataVisualization*" (
    echo ERROR: DataVisualization library found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\lib\Qt6Quick3D*" (
    echo ERROR: Quick3D library found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)
if exist "%QT_INSTALL_PATH%\lib\Qt6Designer*" (
    echo ERROR: Designer library found - GPL component present!
    set GPL_COMPONENTS_FOUND=1
)

echo.
if %GPL_COMPONENTS_FOUND%==0 (
    echo SUCCESS: No GPL components detected in Qt installation!
    echo The build successfully excluded all GPL-licensed binaries.
) else (
    echo ERROR: GPL components were found in the installation!
    echo Please check the build configuration and exclusion lists.
    exit /b 1
)

echo.
echo #################################################
echo Verification complete.
echo ################################################# 