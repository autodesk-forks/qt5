7z e art-bobcat-downloads\3dsmax\openssl\1.0.2j\openssl-1.0.2j.zip -y -spf
move openssl ../
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64 10.0.10586.0
perl ./init-repository -f
SET _ROOT=%WORKSPACE%
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
copy C:\bin\jom.exe
cd qtcanvas3d
git checkout 5.6
cd ..
python adsk_3dsmax_build.py
cd dist
7z a -t7z %WORKSPACE%\stage\5.6.2-3dsmax-Qt-%BUILD_NUMBER%-win-vc140-10.0.10586.0.7z *
