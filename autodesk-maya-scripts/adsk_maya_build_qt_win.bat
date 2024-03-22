@echo off
REM Parameter 1 - Absolute path to workspace directory
if [%1]==[] (
    echo Need to pass workspace directory to the script
    exit /b 1
)

set DO_CONFIGURE=1
set DO_BUILD=1
set DO_INSTALL=1
set DO_ZIP=1
for %%a in (%*) do (
    if [%%a]==[--build] (
        set DO_CONFIGURE=0
        set DO_INSTALL=0
        set DO_ZIP=0
    )
    if [%%a]==[--install] (
        set DO_CONFIGURE=0
        set DO_BUILD=0
    )
    if [%%a]==[--zip] (
        set DO_CONFIGURE=0
        set DO_BUILD=0
        set DO_INSTALL=0
    )
)

REM Environment Variable - QTVERSION - Version of Qt to build
if not defined QTVERSION (
    echo QTVERSION is NOT defined. Example: SET QTVERSION=6.5.0
    exit /b 1
) else (
    echo QTVERSION=%QTVERSION%
)

set vcvarsall=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat
set vcvarsall_enterprise=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat
if not defined VSCMD_VER (
    REM Activate Visual Studio compiler for amd64 architecture (at default install location)
    if exist "%vcvarsall%" (
        call "%vcvarsall%" amd64
    ) else if exist "%vcvarsall_enterprise%" (
        call "%vcvarsall_enterprise%" amd64
    ) else (
        echo Microsoft Visual Studio 2022 appears not to be installed. aborting.
        echo vcvars paths tested:
        echo     %vcvarsall%
        echo     %vcvarsall_enterprise%
        exit /b 1
    )
) else (
    echo vcvarsall.bat already called
)

REM Location of the workspace directory (root of the folder structure)
set WORKSPACE_DIR=%1

REM Location of the source code directory (top of git tree - qt5.git)
set SOURCE_DIR=%WORKSPACE_DIR%\src

REM Location where the final build will be located, as defined by the -prefix option
set INSTALL_DIR=%WORKSPACE_DIR%\install\qt_%QTVERSION%

REM Location where the Python executable will be copied
set BUILD_DIR=%WORKSPACE_DIR%\b
if not exist "%BUILD_DIR%" (
    echo warning: build directory %BUILD_DIR% does not exist. Creating.
    mkdir "%BUILD_DIR%"
    echo Created.
)

REM Location of openssl root directory (optional) within the external
REM dependencies directory.
set OPENSSL_ROOT_DIR=%WORKSPACE_DIR%\external_dependencies\openssl\1.1.1g\RelWithDebInfo
set CMAKE_DIR=%WORKSPACE_DIR%\external_dependencies\cmake-3.26.0-windows-x86_64
set NINJA_DIR=%WORKSPACE_DIR%\external_dependencies
set NODE_DIR=%WORKSPACE_DIR%\external_dependencies\node-v16.14.0-win-x64
set GNUWIN32_DIR=%WORKSPACE_DIR%\external_dependencies\gnuwin32
for %%F in ("%PYTHONEXE%") do set PYTHON_DIR=%%~dpF
for /F "delims=" %%i in ("%PYTHONEXE%") do set PYTHONEXE_BASENAME=%%~nxi

if not exist "%PYTHONEXE%" (
    echo error: %PYTHONEXE% doesn't exist.
    exit /b 1
)

if "%PYTHONEXE_BASENAME%" == "python.exe" (
    if not exist "%PYTHON_DIR%python3.exe" (
        cp "%PYTHONEXE%" "%PYTHON_DIR%python3.exe"
    )
)

REM Prepend to PATH
echo PATH before amending: %PATH%
path | find /i "%BUILD_DIR%" >nul 2>&1 || set PATH=%BUILD_DIR%;%PATH%
path | find /i "%SOURCE_DIR%\qtbase\bin" >nul 2>&1 || set PATH=%SOURCE_DIR%\qtbase\bin;%PATH%
path | find /i "%GNUWIN32_DIR%\bin" >nul 2>&1 || set PATH=%GNUWIN32_DIR%\bin;%PATH%
path | find /i "%CMAKE_DIR%\bin" >nul 2>&1 || set PATH=%CMAKE_DIR%\bin;%PATH%
path | find /i "%NINJA_DIR%" >nul 2>&1 || set PATH=%NINJA_DIR%;%PATH%
path | find /i "%NODE_DIR%" >nul 2>&1 || set PATH=%NODE_DIR%;%PATH%
path | find /i "%PYTHON_DIR%" >nul 2>&1 || set PATH=%PYTHON_DIR%;%PATH%
echo PATH after amending: %PATH%

FOR /F "tokens=3 delims= " %%v IN ('cmake --version') DO ( set CMAKE_VERSION=%%v && goto CMAKE_VER_DONE )
:CMAKE_VER_DONE
FOR /F "delims=" %%v IN ('ninja --version') DO set NINJA_VERSION=%%v
FOR /F "delims=" %%v IN ('node --version') DO set NODE_VERSION=%%v
FOR /F "tokens=3 delims= " %%v IN ('gperf --version') DO ( set GPERF_VERSION=%%v && goto GPERF_VER_DONE )
:GPERF_VER_DONE
python3 --version
which python
which python3
echo CMake %CMAKE_VERSION%
echo ninja %NINJA_VERSION%
echo nodejs %NODE_VERSION%
echo gperf %GPERF_VERSION%

REM Ensure that python html5lib is installed, required by webengine
python3 -m pip install --no-input html5lib

REM Move to build directory, change between drives letters if necessary.
if %BUILD_DIR:~1,1%==: %BUILD_DIR:~0,2%
cd /d %BUILD_DIR%

REM Don't set variables inside of () groups - they will not expand properly.
set COMMERCIAL_MODULES_TO_SKIP=-skip qtcharts -skip qtdatavis3d -skip qtlottie ^
-skip qtmqtt -skip qtnetworkauth -skip qtquick3d -skip qtquicktimeline ^
-skip qtvirtualkeyboard -skip qtwayland
set MODULES_TO_SKIP=%COMMERCIAL_MODULES_TO_SKIP% -skip qtactiveqt ^
-skip qtconnectivity -skip qtcoap -skip qtopcua -skip qtpdf ^
-skip qtquick3dphysics -skip qtquickeffectmaker
if %DO_CONFIGURE%==1 (
    REM Define the modules to skip (because they are under commercial license)

    REM Configure the build
    REM Configure options: https://wiki.qt.io/Qt_6.2_Tools_and_Versions (doesn't presently match since cmake is used directly there)
    call %SOURCE_DIR%\configure -opensource -confirm-license ^
-prefix %INSTALL_DIR% -debug-and-release -nomake tests -nomake examples ^
-force-debug-info -optimized-tools -opengl desktop -feature-qtwebengine-build ^
-plugin-sql-sqlite %MODULES_TO_SKIP% -openssl-runtime -- ^
-DOPENSSL_ROOT_DIR=%OPENSSL_ROOT_DIR% ^
-D_SILENCE_ALL_CXX23_DEPRECATION_WARNINGS=1 || ^
echo "**** Failed to configure build ****" && exit /b 1
    REM Note - prior line needs to be without starting whitespace or the
    REM command will fail. Has to do with how ^ continuation works (seems like a
    REM bug).
)

if %DO_BUILD%==1 (
    REM Build
    cmake --build . --parallel || echo "**** Failed to build ****" && exit /b 1
)

if %DO_INSTALL%==1 (
    ninja install:all || echo "**** Failed to create install ****" && exit /b 1
)

if %DO_ZIP%==1 (
    REM Compress folders for Maya devkit
    cd %INSTALL_DIR%
    7z a -tzip qt_%QTVERSION%_vc14-include.zip .\include\* && ^
7z a -tzip qt_%QTVERSION%_vc14-cmake.zip .\lib\cmake\* && ^
7z a -tzip qt_%QTVERSION%_vc14-mkspecs.zip .\mkspecs\* && ^
echo "==== Success ====" || echo "**** Failed to create zip files ****" && exit /b 1
    REM Note - prior 3 lines need to be without starting whitespace or the
    REM command will fail. Has to do with how ^ continuation works (seems like a
    REM bug).
)

:END
