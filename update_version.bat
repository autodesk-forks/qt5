@echo off
setlocal ENABLEDELAYEDEXPANSION

set Version=%1
for /F "tokens=1-4 delims=." %%a in ("%Version%") do (
	set Version_releasemajor=%%a
	set Version_releaseminor=%%b
	set Version_buildmajor=%%c
	set Version_buildminor=%%d
)
if %Version_releasemajor%.==. echo ERROR: QT Version not found&exit /b 1
if %Version_releaseminor%.==. echo ERROR: QT Version not found&exit /b 1
if %Version_buildmajor%.==. echo ERROR: QT Version not found&exit /b 1
if %Version_buildminor%.==. echo ERROR: QT Version not found&exit /b 1

set Dir=%~dp0
set Dir=!Dir:~,-1!
set qtdeclarative_dir=%Dir%\qtdeclarative\tools
set qttools_dir=%Dir%\qttools\src

for %%a in (%qtdeclarative_dir%\qml\qml.pro,%qtdeclarative_dir%\qmleasing\qmleasing.pro,%qtdeclarative_dir%\qmlimportscanner\qmlimportscanner.pro,%qtdeclarative_dir%\qmljs\qmljs.pro,%qtdeclarative_dir%\qmllint\qmllint.pro,%qtdeclarative_dir%\qmlmin\qmlmin.pro,%qtdeclarative_dir%\qmlplugindump\qmlplugindump.pro,%qtdeclarative_dir%\qmlprofiler\qmlprofiler.pro,%qtdeclarative_dir%\qmlscene\qmlscene.pro,%qtdeclarative_dir%\qmltestrunner\qmltestrunner.pro,%qtdeclarative_dir%\qmltime\qmltime.pro) do (
	if exist "%%a" (
		echo sed -e "/VERSION/s/{QT_VERSION}.0/{QT_VERSION}.%Version_buildminor%/" "%%a"
		sed -e "/VERSION/s/{QT_VERSION}.0/{QT_VERSION}.%Version_buildminor%/" "%%a" > "%temp%\temp.txt"
		move /Y "%temp%\temp.txt" "%%a" || echo "ERROR: Failed to update %%a."
	)
)

for %%a in (%qttools_dir%\assistant\assistant\assistant.pro,%qttools_dir%\designer\src\designer\designer.pro,%qttools_dir%\linguist\linguist\linguist.pro) do (
	if exist "%%a" (
		echo sed -e "/VERSION/s/{QT_VERSION}.0/{QT_VERSION}.%Version_buildminor%/" "%%a"
		sed -e "/VERSION/s/{QT_VERSION}.0/{QT_VERSION}.%Version_buildminor%/" "%%a" > "%temp%\temp.txt"
		move /Y "%temp%\temp.txt" "%%a" || echo "ERROR: Failed to update %%a."
	)
)

for /F %%a in ('dir /b /ad') do (
	if exist %Dir%\%%a\.qmake.conf (
		echo sed -e "/^MODULE_VERSION/s/5.12.7/%Version%/" %Dir%\%%a\.qmake.conf
		sed -e "/^MODULE_VERSION/s/5.12.7/%Version%/" %Dir%\%%a\.qmake.conf > "%temp%\temp.txt"
		move /Y "%temp%\temp.txt" %Dir%\%%a\.qmake.conf || echo "ERROR: Failed to update %Dir%\%%a\.qmake.conf."
	)
	
)

for /f %%a in (update_version_plugins_projects.txt) do (
	if exist "%%a" (
		echo Appended version info into %%a
		echo. >> "%%a"
		echo. >> "%%a"
		echo win32 { >> "%%a"
   		echo    VERSION = $${QT_VERSION}.%Version_buildminor% >> "%%a"
		echo } else { >> "%%a"
   		echo    VERSION = $${QT_VERSION}>> "%%a"
		echo } >> "%%a"
		echo. >> "%%a"
	)
)
