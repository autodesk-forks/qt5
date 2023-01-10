#!/bin/bash
#################################################
#@file BuildQtOnLinux.sh
#@brief Build script for Qt 6.2.4 version on Linux
#@team FARA/CM (Consistant Material scrum team)                 
#@author Huimin Wen(Jess)                                                             
#@date 1/3/2023
#################################################


#################################################
#Setup environment
#Set the number of openning files' limit to 4096 
ulimit -n 4096
#################################################


#################################################
#Setup environment variables
export PATH=/DATA/wenhm/CWorkSpace/Qt6/tools/CMake/bin/:$PATH
export CMAKE_TOOL=/DATA/wenhm/CWorkSpace/Qt6/tools/CMake/bin/cmake
export LLVM_INSTALL_DIR=/usr/lib/llvm-10
#export PostgreSQL_ROOT=/usr/local/Cellar/postgresql@11/11.14_1
#################################################
#cmake --version
#exit


#################################################
#Common Functions

#################################################


#################################################
#Set options for this shell script
#srcpath=`dirname $0`
#srcpath=`(cd "$srcpath"; pwd)`
#echo $srcpath
CUR_SCRIPT_PATH=`dirname $0`
CUR_SCRIPT_PATH=`(cd "$srcpath"; pwd)`
#################################################


#################################################
#Set Qt configuration option variables
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."
QT_INSTALL_PATH="$QT_ROOT_PATH/../qt_linux_opensource_6.2.4.0"
QT_3RDPARTY_PATH="${CUR_BAT_PATH}/3rdParty"
#Set CONFIG_PREFIX="${QT_ROOT_PATH}/qtbase"
CONFIG_PREFIX=$QT_INSTALL_PATH
CONFIG_EXT_PREFIX=$QT_INSTALL_PATH
QT_MODULE_SKIPPED=" -skip qtlocation "

echo QT_ROOT_PATH:$QT_ROOT_PATH
echo CUR_SCRIPT_PATH:$CUR_SCRIPT_PATH
pwd

#Step into the Qt root directory
cd ${QT_ROOT_PATH}
pwd
#################################################
#exit


##############################################


#################################################
#Git init and sync

#Initialize the repository
perl init-repository

#Sync the submoudles url, maybe it's not necessary
git submodule sync

#Submodule update
git submodule update --init --recursive
#################################################


#################################################
#Git clean up

#git clean -xfd
#git submodule foreach --recursive git clean -xfd
#git reset --hard
#git submodule foreach --recursive git reset --hard
#git submodule update --init --recursive
#################################################


#################################################
#Configure the Qt options 
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64" -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo
./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo
#################################################
#exit


#################################################
#Build Qt with the configuration options
#cmake --build . --parallel
#${CMAKE_TOOL}   --build . --parallel
#${CMAKE_TOOL}   --build . --parallel 4
${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
#################################################


#################################################
#Install Qt build output to the directory of prefix option
#cmake --install .
ninja install
#################################################


#################################################
#Delete all "*-debug.cmake" files
pushd ${QT_INSTALL_PATH}
find ./lib/cmake -type file -name "*-debug.cmake" -delete

#Delete all "*_debug" files
find . -type file -name "*_debug" -delete
popd 
#################################################


#################################################
#Change the rpath of QtWebEngineProcess
pushd ${QT_INSTALL_PATH}

#add new rpath into QtWebEngineProcess
if  [ -f  "lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess" ];then
  echo  "QtWebEngineProcess does exist. Now begin to correct the rpath of QtWebEngineProcess."

  #install_name_tool -rpath /Volumes/DATA/Qt6/Qt6.2.4/qt5/qtbase/lib @loader_path/../../../../../../../ QtWebEngineProcess
  install_name_tool -rpath /Volumes/DATA/Qt6/Qt6.2.4/qt5/qtbase/lib @loader_path/../../../../../../../ lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess

  #install_name_tool -add_rpath @loader_path/../../../../../../../ QtWebEngineProcess
  install_name_tool -add_rpath @loader_path/../../../../../../../ lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess
else
  echo  "QtWebEngineProcess does not exist."
fi

popd
#################################################


#################################################
echo Building is done. You should check whether there exist errors.
#################################################
