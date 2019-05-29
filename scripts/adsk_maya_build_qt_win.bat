if [%1]==[] (
   echo "Need to pass workspace directory to the script"
   exit /b 1
)

if not defined QTVERSION (
	echo QTVERSION is NOT defined.  Example: SET QTVERSION=5.12.2
	exit /b 1
)
else (
	echo QTVERSION=%QTVERSION%
)

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64
@echo on

set WORKDIR=%1
set SRCDIR=%WORKDIR%\src
set INSTALLDIR=%WORKDIR%\install\qt_%QTVERSION%
set BUILDDIR=%WORKDIR%\build

echo %SRCDIR%
SET _ROOT=%SRCDIR%
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
set OPENSSL_INCLUDE=%WORKDIR%\artifactory\openssl\1.0.2h\include

cd /d %BUILDDIR%

call %SRCDIR%\configure -prefix %INSTALLDIR% -debug-and-release -force-debug-info -mp -optimized-tools -opensource -confirm-license -opengl desktop -directwrite -plugin-sql-sqlite -I %OPENSSL_INCLUDE% -openssl-runtime -no-warnings-are-errors || ^
echo "**** Failed to configure build ****" && exit /b 1

nmake || echo "**** Failed to build ****" && exit /b 1

nmake install || echo "**** Failed to create install ****" && exit /b 1

cd %INSTALLDIR%
7z a -tzip qt_%QTVERSION%_vc14-include.zip .\include\* && ^
7z a -tzip qt_%QTVERSION%_vc14-cmake.zip .\lib\cmake\* && ^
7z a -tzip qt_%QTVERSION%_vc14-mkspecs.zip .\mkspecs\* && ^
echo "==== Success ====" || echo "**** Failed to create zip files ****" && exit /b 1