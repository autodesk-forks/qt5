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
QT_BUILD_VERSION=6.2.4.0
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."

QT_BUILD_PATH_DEBUG="$QT_ROOT_PATH/../qt-build-debug"
QT_BUILD_PATH_RELEASE="$QT_ROOT_PATH/../qt-build-release"

QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/../qt_linux_opensource_${QT_BUILD_VERSION}_debug"
QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/../qt_linux_opensource_${QT_BUILD_VERSION}_release"

QT_3RDPARTY_PATH="${CUR_BAT_PATH}/3rdParty"

#Set CONFIG_PREFIX="${QT_ROOT_PATH}/qtbase"
CONFIG_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

CONFIG_EXT_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_EXT_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

QT_MODULE_SKIPPED=" -skip qtlocation "

echo QT_ROOT_PATH:$QT_ROOT_PATH
echo CUR_SCRIPT_PATH:$CUR_SCRIPT_PATH
pwd

#Enter the Qt root directory
cd ${QT_ROOT_PATH}
pwd
#################################################
#exit


#################################################


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
#mkdir ~/qt-build
#cd ~/qt-build
#~/qt-source/configure -prefix /opt/Qt6

#Configuraion for release version
#mkdir ../qt-build-release
mkdir $QT_BUILD_PATH_RELEASE
#cd ../qt-build-release
pushd $QT_BUILD_PATH_RELEASE

#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64" -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Summary.txt 2>&1
#${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -release -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Summary.txt 2>&1

${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_RELEASE} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -release -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Release.Summary.txt 2>&1
popd

#Configuration for debug version
mkdir $QT_BUILD_PATH_DEBUG
pushd $QT_BUILD_PATH_DEBUG
${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_DEBUG} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Debug.Summary.txt 2>&1
popd
#################################################
#exit


#################################################
#Build Qt with the configuration options
#cmake --build . --parallel
#${CMAKE_TOOL}   --build . --parallel
#${CMAKE_TOOL}   --build . --parallel 4
#${CMAKE_TOOL}   --build . --parallel 4 -- -j 4

#Build for release version
pushd $QT_BUILD_PATH_RELEASE
${CMAKE_TOOL}   --build . --parallel
#${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
popd

#Build for debug version
pushd $QT_BUILD_PATH_DEBUG
${CMAKE_TOOL}   --build . --parallel
#${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
popd
#################################################
#exit


#################################################
#Install Qt build output to the directory of prefix option
#cmake --install .
#ninja install

#Installation for release version
pushd $QT_BUILD_PATH_RELEASE
ninja install
popd

#Installation for debug version
pushd $QT_BUILD_PATH_DEBUG
ninja install
popd
#################################################


#################################################
#Delete all "*-debug.cmake" files
pushd ${QT_INSTALL_PATH_RELEASE}
find ./lib/cmake -type f -name "*-debug.cmake" -delete

#Delete all "*_debug" files
find . -type f -name "*_debug" -delete
popd


pushd ${QT_INSTALL_PATH_DEBUG}
find ./lib/cmake -type f -name "*-debug.cmake" -delete

#Delete all "*_debug" files
find . -type f -name "*_debug" -delete
popd 
#################################################


#################################################
#Change the rpath of QtWebEngineProcess
pushd ${QT_INSTALL_PATH_RELEASE}

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
