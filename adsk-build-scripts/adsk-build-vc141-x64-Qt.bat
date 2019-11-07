
python --version
cmake --version
ninja --version
C:\bin\jom.exe /VERSION

for /f "usebackq delims=" %%i in (`"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -prerelease -latest -property installationPath`) do (
  IF exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" (
    CALL "%%i\VC\Auxiliary\Build\vcvarsall.bat" amd64 10.0.17134.0
  )
)

SET

@REM NEEDED TO BE REMOVED ONCE SINCE IT WAS SCREWED UP - SUBMODULES MAY FAIL :(
@REM RMDIR /s /q qt3d

CHCP
CHCP 65001

@REM reset version change that might have been there from the last build
IF exist qtbase\qmake\generators\win32\winmakefile.cpp (
  pushd qtbase
  git checkout -- qmake/generators/win32/winmakefile.cpp
  popd
)

perl ./init-repository -f

@REM git submodule update --init qtbase

@REM pushd qtwebengine
@REM git submodule update --init
@REM popd

copy /V C:\bin\jom.exe %WORKSPACE%\jom.exe

python adsk-build-scripts\adsk_3dsmax_build.py