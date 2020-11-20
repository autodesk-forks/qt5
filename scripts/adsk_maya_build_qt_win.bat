if [%1]==[] (
    echo Need to pass workspace directory to the script
    exit /b 1
)

if not defined QTVERSION (
    echo QTVERSION is NOT defined.  Example: SET QTVERSION=5.15.1
    exit /b 1
) else (
    echo QTVERSION=%QTVERSION%
)

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64
@echo on

REM Define Paths
REM Folder structure:
REM workdir               (root directory, also defined as workspace)
REM - workdir/src         (contains the source code)
REM - workdir/install     (location where the artifact is packaged)
REM - workdir/build       (location where the artifact is built)
REM Note: Jenkinsfile takes care of the folder structure setup
set WORKDIR=%1
set SRCDIR=%WORKDIR%\src
set INSTALLDIR=%WORKDIR%\install\qt_%QTVERSION%
set BUILDDIR=%WORKDIR%\build

echo %SRCDIR%
set _ROOT=%SRCDIR%
set PATH=%BUILDDIR%;%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
REM TODO : Include OpenSSL from artifactory once artifact is created
REM set OPENSSL_INCLUDE=%WORKDIR%\artifactory\openssl\1.0.2h\include

REM Make sure there's a "python2.exe" in the path that isn't the Git
REM mingw version (which was the cause of errors previously).
REM Make sure it's in a path without spaces (webkit barfs on paths with spaces).
if exist %BUILDDIR%\python2.exe (
    rm %BUILDDIR%\python2.exe
) >nul 2>&1
copy C:\Python27\python.exe %BUILDDIR%\python2.exe >nul 2>&1

python2 -c "print('test Python')" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Python2 executable invalid!
    exit /b 1
)

cd /d %BUILDDIR%

REM TODO : Include OpenSSL from artifactory once artifact is created
REM To have OpenSSL, add the following before "-no-warnings-are-errors": -I %OPENSSL_INCLUDE% -openssl-runtime 
call %SRCDIR%\configure -opensource -confirm-license -prefix %INSTALLDIR% -debug-and-release -force-debug-info -mp -optimized-tools -opengl desktop -directwrite -plugin-sql-sqlite -skip qtnetworkauth -skip qtpurchasing -no-warnings-are-errors || ^
echo "**** Failed to configure build ****" && exit /b 1

nmake || echo "**** Failed to build ****" && exit /b 1

nmake install || echo "**** Failed to create install ****" && exit /b 1

cd %INSTALLDIR%
7z a -tzip qt_%QTVERSION%_vc14-include.zip .\include\* && ^
7z a -tzip qt_%QTVERSION%_vc14-cmake.zip .\lib\cmake\* && ^
7z a -tzip qt_%QTVERSION%_vc14-mkspecs.zip .\mkspecs\* && ^
echo "==== Success ====" || echo "**** Failed to create zip files ****" && exit /b 1
