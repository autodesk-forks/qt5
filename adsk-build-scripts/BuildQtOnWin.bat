@rem #################################################
@rem @file BuildQtOnWin.bat
@rem @brief Build script for Qt 6.2.4 windows x64/x86 version
@rem @team FARA/CM (Consistant Material scrum team)
@rem @author Huimin Wen(Jess)
@rem @date 12/7/2021
@rem #################################################


@rem #################################################
@rem Set options for this bat
@echo on
@rem CUR_BAT_PATH stores the path of this bat
set CUR_BAT_PATH=%~dp0


@rem CONFIGURE_LOG stores the filename of configuration output log 
@rem BuildQt.bat %DAILY_BUILD_WITH_LOG_PARAM% 1>DailyBuild.log 2>DailyBuildError.log
@rem  1>stdout.output  2>stderr.output
set CONFIGURE_LOG=BuildQt.bat.Configure.log
set CONFIGURE_ERR_LOG=BuildQt.bat.Configure.Error.log

@rem BUILD_LOG stores the filename of building output log 
set BUILD_LOG=BuildQt.bat.Build.Log
set BUILD_ERR_LOG=BuildQt.bat.Build.Error.log

@rem BUILD_DOC_LOG stores the filename of building doc output log 
set BUILD_DOC_LOG=BuildQt.bat.BuildDoc.Log
set BUILD_DOC_ERR_LOG=BuildQt.bat.BuildBuildDoc.Error.log

@rem INSTALL_LOG stores the filename of installation output log
set INSTALL_LOG=BuildQt.bat.Install.log
set INSTALL_ERR_LOG=BuildQt.bat.Install.Error.log
@rem #################################################


@rem #################################################
@rem Set the path of Visual Studio 2019 vcvars64.bat

@rem Auto detect the path of Visual Studio 2019 vcvars64.bat by using vswhere.exe
set VSWHERE_TOOL="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set VCVARS64.BAT="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
setlocal enabledelayedexpansion
for /f "usebackq tokens=*" %%i in (`%VSWHERE_TOOL%  -version [16.0^,17.0^) -requires Microsoft.Component.MSBuild -property installationPath`) do (
	set VCVARS64.BAT="%%i\VC\Auxiliary\Build\vcvars64.bat"
	@rem echo !VCVARS64.BAT!
)
@rem echo VCVARS64.BAT:%VCVARS64.BAT%

@rem set VCVARS64.BAT="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
if not exist %VCVARS64.BAT% (
	set VCVARS64.BAT="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
)
@rem echo VCVARS64.BAT:%VCVARS64.BAT%

@rem Revalidate the path
@rem set VCVARS64.BAT="D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
if not exist %VCVARS64.BAT% (
	@rem set DEVENV="%VS100COMNTOOLS%..\IDE\devenv.exe"(Only Visual Studio 2010 could use the %VS100COMNTOOLS% enviroment variable)
	set VCVARS64.BAT="D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
)	
echo VCVARS64.BAT:%VCVARS64.BAT%
@rem #################################################
@rem goto :eof


@rem #################################################
@rem Setup Visual Studio environment variables
@rem Set Visual Studio compiling environment

@rem %comspec% /k "d:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
@rem call  %comspec% /k "d:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
@rem call "d:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
call %VCVARS64.BAT%
@rem #################################################
@rem goto :eof


@rem #################################################
@rem Set Qt configuration option variables
@echo on
set QT_ROOT_PATH="%CUR_BAT_PATH%.."
set QT_INSTALL_PATH="%QT_ROOT_PATH%\..\qt_win_intel64_opensource_v140.6.2.4.0"
set QT_3RDPARTY_PATH="%CUR_BAT_PATH%3rdParty"
@rem set CONFIG_PREFIX="%QT_ROOT_PATH%\qtbase"
set CONFIG_PREFIX=%QT_INSTALL_PATH%
set CONFIG_EXT_PREFIX=%QT_INSTALL_PATH%
set QT_MODULE_SIKPPED= -skip qtlocation 

@rem Step into the Qt root directory
cd /d %QT_ROOT_PATH%

@rem Set an environment variable called ${PostgreSQL_ROOT} that points to the root of where you have
@rem @ref qt5\qtbase\cmake\FindPostgreSQL.cmake
@rem set PostgreSQL_ROOT="D:\download\tools\postgresql-14.1-1-windows-x64-binaries\pgsql"
@rem setx PostgreSQL_ROOT "D:\download\tools\postgresql-14.1-1-windows-x64-binaries\pgsql"
@rem #################################################
@rem goto :eof


@rem goto LabelConfigure
@rem goto LabelCopy
@rem #################################################
@rem Git init and sync

@rem Initialize the repository
perl init-repository

@rem Sync the submoudles url, maybe it's not necessary
git submodule sync

@rem Submodule update
@rem git submodule update
@rem git submodule update --init
@rem git submodule update --init --recursive --force
git submodule update --init --recursive
@rem #################################################


@rem #################################################
@rem Preparation for configuration
@rem Delete some unnecessary folders which will block the configuration
@rem rd /s /q  %QT_ROOT_PATH%\qtlocation
@rem #################################################


:LabelConfigure
@rem #################################################
@rem Configure Qt build options ----set -prefix -extprefix options
@echo Configuring Qt...

@rem We should use start to call configure.bat, for there exist exit statements in the bat.
@rem start configure -opensource -confirm-license -prefix %CONFIG_PREFIX% -extprefix  %CONFIG_EXT_PREFIX%	^
@rem 		-platform win32-msvc -opengl dynamic -plugin-sql-sqlite -qt-libjpeg -qt-zlib		^
@rem 		-debug-and-release -force-debug-info -developer-build -nomake examples		^
@rem 		-nomake tests -no-warnings-are-errors

@rem call  %comspec% /k "configure -opensource -confirm-license -prefix %CONFIG_PREFIX% -extprefix  %CONFIG_EXT_PREFIX% -platform win32-msvc -opengl dynamic -plugin-sql-sqlite -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -developer-build -nomake examples -nomake tests -no-warnings-are-errors  & exit"

@rem call  %comspec% /k "configure -opensource -confirm-license -prefix %CONFIG_PREFIX% -extprefix  %CONFIG_EXT_PREFIX% -platform win32-msvc " ^
@rem                    " -opengl dynamic -plugin-sql-sqlite  -sql-psql -plugin-sql-psql -openssl-linked -qt-libjpeg -qt-zlib  " ^
@rem                    " -debug-and-release -force-debug-info -developer-build -nomake examples -nomake tests -no-warnings-are-errors  & exit "

call  %comspec% /k "configure -opensource -confirm-license -prefix %CONFIG_PREFIX%  -platform win32-msvc " ^
                   " -opengl dynamic -plugin-sql-sqlite  -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib  " ^
                   " -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors  -no-wmf " ^
                   " %QT_MODULE_SIKPPED% " ^
                   " 1>%CONFIGURE_LOG% 2>%CONFIGURE_ERR_LOG% & exit "
			      
@rem #################################################
@rem goto :eof


:LabelBuild
@rem #################################################
@rem Build all modules
@echo Building Qt...
cmake --build . --parallel 1>%BUILD_LOG% 2>%BUILD_ERR_LOG%

@rem Build single module
@rem cmake --build . --target qtmqtt
@rem #################################################


:LabelBuildDocs
@rem #################################################
@rem Build Qt document
@echo Building Qt documents...
@rem If you want to generate the docs, you shoude uncomment the next statement
@rem ninja docs 1>%BUILD_DOC_LOG% 2>%BUILD_DOC_ERR_LOG%
@rem #################################################


:LabelInstall
@rem #################################################
@rem Install Qt binary to %CONFIG_PREFIX% path
@echo Installing Qt...
ninja install 1>%INSTALL_LOG% 2>%INSTALL_ERR_LOG%
@rem #################################################


:LabelCopy
@rem #################################################
@rem Copy some corresponding files to Compilers directory
@echo Copying thirdparty files...

set QT_INSTALL_COMPILER_PATH=%CONFIG_PREFIX%\compilers
@rem Create compilers directory
mkdir %QT_INSTALL_COMPILER_PATH%

@rem Copy files...
@rem echo F|xcopy /d /y /h "Update\QtCored.dll" "%PackageDir%\QtCored.dll"
@rem echo D|xcopy /d /y /h /e "MsvcDll\*" "%PackageDir%\bin\*"

echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\uic.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\rcc.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\Qt6Xml.dll"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\Qt6Core.dll"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qmlcachegen.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qmake.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\moc.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lupdate-pro.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lupdate.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lrelease.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lprodump.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lconvert.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\idc.exe"  %QT_INSTALL_COMPILER_PATH%

echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\androiddeployqt.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\androidtestrunner.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\cmake_automoc_parser.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\lrelease-pro.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qlalr.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qml.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qtpaths.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qvkgen.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\qwebengine_convert_dict.exe"  %QT_INSTALL_COMPILER_PATH%
echo F| xcopy /d /y /h "%QT_INSTALL_PATH%\bin\tracegen.exe"  %QT_INSTALL_COMPILER_PATH%

echo F| xcopy /d /y /h "%QT_3RDPARTY_PATH%\*"  %QT_INSTALL_PATH%\bin\*
@rem #################################################


:LabelEnd
@rem #################################################
@echo Qt building is over.
@rem #################################################
