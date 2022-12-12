REM Parameter 1 - Absolute path to workspace directory
if [%1]==[] (
    echo Need to pass workspace directory to the script
    exit /b 1
)

REM Environment Variable - QTVERSION - Version of Qt to build
if not defined QTVERSION (
    echo QTVERSION is NOT defined. Example: SET QTVERSION=5.15.2
    exit /b 1
) else (
    echo QTVERSION=%QTVERSION%
)

REM Activate Visual Studio compiler for amd64 architecture (at default install location) 
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64
@echo on

REM Location of the workspace directory (root of the folder structure)
set WORKSPACE_DIR=%1

REM Location of the source code directory (top of git tree - qt5.git)
set SOURCE_DIR=%WORKSPACE_DIR%\src

REM Location where the final build will be located, as defined by the -prefix option
set INSTALL_DIR=%WORKSPACE_DIR%\install\qt_%QTVERSION%

REM Location where the Python executable will be copied
set BUILD_DIR=%WORKSPACE_DIR%\build

REM Location of Python executable
set PYTHON_EXE_DIR="C:\Python27\python.exe"

REM Location of openssl include directory (optional) within the external dependencies directory
set OPENSSL_INCLUDE_DIR=%WORKSPACE_DIR%\external_dependencies\openssl\1.1.1g\RelWithDebInfo\include
set NODE_DIR=%WORKSPACE_DIR%\external_dependencies\node-v16.14.0-win-x64

REM Python is a dependency required to build Qt
REM - To make sure there is a "python2.exe" in the PATH that is not Git's mingw version (causes errors),
REM   copy the python executable into the build directory and prepend the path to the build directory to PATH
REM - Make sure its path is without spaces (webkit fails to build on paths with spaces).
if exist %BUILD_DIR%\python2.exe (
    rm %BUILD_DIR%\python2.exe
) >nul 2>&1
copy %PYTHON_EXE_DIR% %BUILD_DIR%\python2.exe >nul 2>&1

python2 -c "print('test Python')" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Python2 executable invalid!
    exit /b 1
)

REM Set Cmake _ROOT environment variable to source code directory
set _ROOT=%SOURCE_DIR%

REM Prepend to PATH
echo PATH before amending: %PATH%
path | find /i "%BUILD_DIR%" >nul 2>&1 || set PATH=%BUILD_DIR%;%PATH%
path | find /i "%_ROOT%\qtbase\bin" >nul 2>&1 || set PATH=%_ROOT%\qtbase\bin;%PATH%
path | find /i "%_ROOT%\gnuwin32\bin" >nul 2>&1 || set PATH=%_ROOT%\gnuwin32\bin;%PATH%
path | find /i "%NODE_DIR%" >nul 2>&1 || set PATH=%NODE_DIR%;%PATH%
echo PATH after amending: %PATH%

FOR /F "delims=" %%v IN ('node --version') DO set NODE_VERSION=%%v
python2 --version
which python2
echo nodejs %NODE_VERSION%

REM Move to build directory (where python2.exe was copied)
cd /d %BUILD_DIR%

REM Define the modules to skip (because they are under commercial license)
set MODULES_TO_SKIP=-skip qtnetworkauth -skip qtpurchasing -skip qtquickcontrols -skip qtquick3d -skip qtlottie -skip qtcharts -skip qtdatavis3d -skip qtvirtualkeyboard -skip qtscript -skip qtwayland -skip qtwebglplugin

REM Configure the build
REM Configure options: https://wiki.qt.io/Qt_5.15_Tools_and_Versions
call %SOURCE_DIR%\configure -opensource -confirm-license -prefix %INSTALL_DIR% -debug-and-release -force-debug-info -mp -optimized-tools -opengl desktop -directwrite -plugin-sql-sqlite %MODULES_TO_SKIP% -I %OPENSSL_INCLUDE_DIR% -openssl-runtime -no-warnings-are-errors || ^
echo "**** Failed to configure build ****" && exit /b 1

REM Build
nmake || echo "**** Failed to build ****" && exit /b 1

nmake install || echo "**** Failed to create install ****" && exit /b 1

REM Compress folders for Maya devkit
cd %INSTALL_DIR%
7z a -tzip qt_%QTVERSION%_vc14-include.zip .\include\* && ^
7z a -tzip qt_%QTVERSION%_vc14-cmake.zip .\lib\cmake\* && ^
7z a -tzip qt_%QTVERSION%_vc14-mkspecs.zip .\mkspecs\* && ^
echo "==== Success ====" || echo "**** Failed to create zip files ****" && exit /b 1
