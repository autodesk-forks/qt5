
python --version
cmake --version
ninja --version
C:\bin\jom.exe /VERSION

@REM use the power of mighty python to find our installation :)
FOR /F "tokens=*" %%F IN ('python adsk-build-scripts\find_vs2017.py') do SET vs2017_path=%%F

@REM call "%vs2017_path%\VC\Auxiliary\Build\vcvarsall.bat" amd64 10.0.17134.0
call "%vs2017_path%\VC\Auxiliary\Build\vcvarsall.bat" amd64

SET

@REM NEEDED TO BE REMOVED ONCE SINCE IT WAS SCREWED UP - SUBMODULES MAY FAIL :(
@REM RMDIR /s /q qt3d

CHCP
CHCP 65001


perl ./init-repository -f --branch
perl ./init-repository -f

@REM git submodule update --init qtbase

@REM pushd qtwebengine
@REM git submodule update --init
@REM popd

SET _ROOT=%WORKSPACE%
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%

copy /V C:\bin\jom.exe %_ROOT%\jom.exe

python adsk-build-scripts\adsk_3dsmax_build.py