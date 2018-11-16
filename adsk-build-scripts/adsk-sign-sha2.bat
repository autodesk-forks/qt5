@echo off
set PASSWORD=%1
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64 10.0.10586.0
for /R %%f in (*.dll,*.exe,*.msi) do (
signtool sign /f C:\bin\autodesk.pfx /p %PASSWORD% /v /fd sha256 /tr http://timestamp.globalsign.com/?signature=sha2 /td sha256 %%f
)
