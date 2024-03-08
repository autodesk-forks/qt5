#!/bin/bash
#################################################
#@file BuildQtOnLinux.sh
#@brief Build script for Qt 6.5.3 version on Linux
#@team FARA/CM (Consistant Material scrum team)                 
#@author Huimin Wen(Jess)
#@email huimin.wen@autodesk.com
#@date 1/3/2023
#################################################


#################################################
#Show some environment variables
#Show the current shell, some shell such as sh 
#will lead some errors when run this shell script
echo The current shell is $0.
ps -p $$
who am i
#################################################


#################################################
#Setup environment
#Set the number of openning files' limit to 4096 
ulimit -n 4096
#################################################


#################################################
#Check gcc version, if the gcc version is lower than 11.1.0, the script return directly
GCCVERSION=$(gcc --version | grep ^gcc | sed 's/^.* //g')
GCCPLUSVERSION=$(g++ --version | grep ^g++ | sed 's/^.* //g')
echo "GCCVERSION=${GCCVERSION} GCCPLUSVERSION=${GCCPLUSVERSION}"

if [ "${GCCVERSION}" \< "11.1.0" ] || [ "${GCCPLUSVERSION}" \< "11.1.0" ]; then
  echo "Error: need gcc 11.1.0 or higher version to build Qt 6.5.* on Linux."
  exit 1
else
  echo "gcc version (${GCCVERSION}) and g++ version (${GCCPLUSVERSION}) is okay."
fi
#################################################


#################################################
#Setup environment variables
#export PATH=/DATA/Qt6/tools/CMake/bin/:$PATH
export PATH=/DATA/Qt6/tools/cmake-3.26.4-linux-x86_64/bin:$PATH
#export CMAKE_TOOL=/DATA/Qt6/tools/CMake/bin/cmake
export CMAKE_TOOL=/DATA/Qt6/tools/cmake-3.26.4-linux-x86_64/bin/cmake
if [ ! -f "$CMAKE_TOOL" ]; then
  CMAKE_TOOL=cmake
fi
echo CMAKE_TOOL:$CMAKE_TOOL

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
QT_BUILD_VERSION=6.5.3.0
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."

QT_BUILD_PATH_DEBUG="$QT_ROOT_PATH/../qt-build-debug"
QT_BUILD_PATH_RELEASE="$QT_ROOT_PATH/../qt-build-release"

# QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/../qt_linux_opensource_${QT_BUILD_VERSION}_debug"
QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/../qt_linux_opensource_debug"
# QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/../qt_linux_opensource_${QT_BUILD_VERSION}_release"
QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/../qt_linux_opensource_release"

QT_3RDPARTY_PATH="${CUR_BAT_PATH}/3rdParty"

#Set CONFIG_PREFIX="${QT_ROOT_PATH}/qtbase"
CONFIG_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

CONFIG_EXT_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_EXT_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

# Remove the installation folder first
if  [  -d  "${QT_INSTALL_PATH_DEBUG}"  ]; then
	rm -rf "${QT_INSTALL_PATH_DEBUG}"
fi

if  [  -d  "${QT_INSTALL_PATH_RELEASE}"  ]; then
	rm -rf "${QT_INSTALL_PATH_RELEASE}"
fi

#The modules in QT_MODULE_EXCLUDED will be excluded from git syncing
#set QT_MODULE_EXCLUDED="-preview,-qtnetworkauth,-qtpurchasing,-qtquick3d,-qtlottie,-qtcharts,-qtdatavis3d,-qtvirtualkeyboard,-qtwebglplugin,-qtactiveqt,-qtconnectivity,-qtcoap,-qtmqtt,-qtopcua,-qtquicktimeline,-qtquickeffectmaker,-qtquick3dphysics"
QT_MODULE_EXCLUDED=-qtlocation,-qtvirtualkeyboard,-qtquicktimeline,-qtquick3d,-qtnetworkauth,-qtdatavis3d,-qtcharts,\
-qtquick3d,-qtquick3dphysics,-qtlottie,-qtcoap,-qtmqtt,-qtwayland

#The modules in QT_MODULE_SKIPPED will be skipped from building
#QT_MODULE_SKIPPED=" -skip qtlocation "
QT_MODULE_SKIPPED=" -skip qtlocation -skip qtvirtualkeyboard -skip qtquicktimeline -skip qtquick3d -skip qtnetworkauth \
                   -skip qtdatavis3d -skip qtcharts -skip qtquick3d -skip qtquick3dphysics \
                   -skip qtlottie -skip qtcoap -skip qtmqtt -skip qtwayland "

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
#perl init-repository
perl init-repository --force --module-subset=default,${QT_MODULE_EXCLUDED}

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
pwd
ls $QT_BUILD_PATH_RELEASE

#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64"
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64" -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo
#./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Summary.txt 2>&1
#${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -release -force-debug-info -separate-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo  1>${CUR_SCRIPT_PATH}/Qt.Configureation.Summary.txt 2>&1
${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_RELEASE} -opengl desktop -plugin-sql-sqlite -sql-psql \
                          -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -release -force-debug-info -separate-debug-info \
                          -nomake examples -nomake tests -no-warnings-are-errors \
                          ${QT_MODULE_SKIPPED} \
                          -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=RelWithDebInfo --log-level=STATUS \
                          1>${CUR_SCRIPT_PATH}/Qt.Configureation.Release.Summary.txt 2>&1
popd

#Configuration for debug version
mkdir $QT_BUILD_PATH_DEBUG
pushd $QT_BUILD_PATH_DEBUG
pwd
ls $QT_BUILD_PATH_DEBUG
${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_DEBUG} -opengl desktop -plugin-sql-sqlite -sql-psql \
                          -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info \
                          -nomake \examples -nomake tests -no-warnings-are-errors \
                          ${QT_MODULE_SKIPPED} \
                          -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR}  -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS_DEBUG="-g -Os" --log-level=STATUS \
                          1>${CUR_SCRIPT_PATH}/Qt.Configureation.Debug.Summary.txt 2>&1
popd
#################################################
#exit


#################################################
# Build Qt with the configuration options
# cmake --build . --parallel
# ${CMAKE_TOOL}   --build . --parallel
# ${CMAKE_TOOL}   --build . --parallel 4
# ${CMAKE_TOOL}   --build . --parallel 4 -- -j 4

# #Build for release version
# pushd $QT_BUILD_PATH_RELEASE
# ${CMAKE_TOOL}   --build . --parallel
# #${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
# popd
# 
# #Build for debug version
# pushd $QT_BUILD_PATH_DEBUG
# ${CMAKE_TOOL}   --build . --parallel
# #${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
# popd

# QtWebEngine module will always failed for out of memory.
# Everytime there would be out of memory after building some source files.
# So we will try 100 times when encounter an error exit code.
error_code1=1
error_code2=1
echo error_code1:$error_code1
echo error_code2:$error_code2
max_loop_count=100
loop_count=0
#while [[ $error_code1 -ne 0 && ${loop_count} -lt ${max_loop_count} ]] ; do
#while [[ ${loop_count} -lt ${max_loop_count} ]] ; do
#while [[ $((${error_code1} -ne 0 || {error_code2} -ne 0)) && ${loop_count} -lt ${max_loop_count} ]] ; do
#while [[ ( ${error_code1} -ne 0 || ${error_code2} -ne 0 ) && ${loop_count} -lt ${max_loop_count} ]]
while [[ ( ${error_code1} -ne 0 || ${error_code2} -ne 0 ) && ${loop_count} -lt ${max_loop_count} ]]
do
  # your unix command here #
  echo "Retried times: ${loop_count}"
  (( loop_count += 1 ))

  #Build for release version
  if [[ ${error_code1} -ne 0 ]] 
  then
      pushd $QT_BUILD_PATH_RELEASE
      ${CMAKE_TOOL}   --build . --parallel
      #${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
      error_code1=$?  
      echo error_code1:$error_code1
      popd
  fi

  #Build for debug version
  if [[ ${error_code2} -ne 0 ]] 
  then
      pushd $QT_BUILD_PATH_DEBUG
      ${CMAKE_TOOL}   --build . --parallel
      #${CMAKE_TOOL}   --build . --parallel 4 -- -j 4
      error_code2=$?  
      echo error_code2:$error_code2
      popd
  fi
done
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
find . -type l -name "*_debug" -delete
popd


pushd ${QT_INSTALL_PATH_DEBUG}
find ./lib/cmake -type f -name "*-debug.cmake" -delete

#Delete all "*_debug" files
find . -type f -name "*_debug" -delete
find . -type l -name "*_debug" -delete
popd 
#################################################


#################################################
#Change the rpath of QtWebEngineProcess
pushd ${QT_INSTALL_PATH_RELEASE}

#add new rpath into QtWebEngineProcess
if  [ -f  "lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess" ];then
  echo  "QtWebEngineProcess does exist. Now begin to correct the rpath of QtWebEngineProcess."

  #install_name_tool -rpath /Volumes/DATA/Qt6/Qt6.5.3.0/qt5/qtbase/lib @loader_path/../../../../../../../ QtWebEngineProcess
  install_name_tool -rpath /Volumes/DATA/Qt6/Qt6.5.3.0/qt5/qtbase/lib @loader_path/../../../../../../../ lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess

  #install_name_tool -add_rpath @loader_path/../../../../../../../ QtWebEngineProcess
  install_name_tool -add_rpath @loader_path/../../../../../../../ lib/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess
else
  echo  "QtWebEngineProcess does not exist."
fi

popd
#################################################


#################################################
# Copy some corresponding files to the Compilers folder

# number=4
# for k in $(seq 1 $number); do echo $k; donefor ()
for BUILD_PATH in ${QT_INSTALL_PATH_RELEASE} ${QT_INSTALL_PATH_DEBUG} 
do
    echo BUILD_PATH:${BUILD_PATH} ...

    QT_INSTALL_COMPILER_PATH=${BUILD_PATH}/compilers
    # Create compilers directory
    mkdir ${QT_INSTALL_COMPILER_PATH}
    echo QT_INSTALL_COMPILER_PATH:${QT_INSTALL_COMPILER_PATH} ...

    cp -rf ${BUILD_PATH}/bin/androiddeployqt ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/androidtestrunner ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/lconvert ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/lrelease ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/lupdate ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmake ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qml ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmldom ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmlformat ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmllint ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmlplugindump ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmlpreview ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmlprofiler ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmlscene ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmltestrunner ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qmltime ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/bin/qtpaths ${QT_INSTALL_COMPILER_PATH}

    cp -rf ${BUILD_PATH}/libexec/cmake_automoc_parser ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/lprodump ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/lrelease-pro ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/lupdate-pro ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/moc ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qlalr ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qmlcachegen ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qmlimportscanner ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qmltyperegistrar ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qvkgen ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/qwebengine_convert_dict ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/rcc ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/tracegen ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/libexec/uic ${QT_INSTALL_COMPILER_PATH}

    cp -rf ${BUILD_PATH}/lib/libQt6Core.prl ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Core.so ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Core.so.6 ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Core.so.6.* ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6WebEngineCore.prl ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6WebEngineCore.so ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6WebEngineCore.so.6 ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6WebEngineCore.so.6.* ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Xml.prl ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Xml.so ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Xml.so.6 ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt6Xml.so.6.* ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt63DCore.prl ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt63DCore.so ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt63DCore.so.6 ${QT_INSTALL_COMPILER_PATH}
    cp -rf ${BUILD_PATH}/lib/libQt63DCore.so.6.* ${QT_INSTALL_COMPILER_PATH}
done
#################################################


#################################################
echo Building is done. You should check whether there exist errors.
#################################################
