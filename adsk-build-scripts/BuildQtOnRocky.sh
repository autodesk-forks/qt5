#!/bin/bash
#################################################
#@file BuildQtOnRocky.sh
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

###############################################################################
#set variables according to the input parameters
#configuration type: [debug | release]
CONFIG_TYPE_PARAM=$1

if [[ "${CONFIG_TYPE_PARAM}" == "" ]]
then 
    echo $CONFIG_TYPE_PARAM
    echo ${CONFIG_TYPE_PARAM}
    echo "${CONFIG_TYPE_PARAM}"
    echo "Usage help : BuildQtOnLinux.sh  [debug | release]"
    exit
fi

#################################################
#Setup environment
#Set the number of openning files' limit to 4096 
ulimit -n 4096
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
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#export PostgreSQL_ROOT=/usr/local/Cellar/postgresql@11/11.14_1
#################################################
cmake --version
ninja --version
ldd --version
gcc --version
python3 --version
openssl version

find / -name "libssl.so*" 2>/dev/null

export OPENSSL_ROOT_DIR=/usr/local/openssl-1.1

locale


#################################################
#Common Functions

#################################################


#################################################
#Set options for this shell script
#srcpath=`dirname $0`
#srcpath=`(cd "$srcpath"; pwd)`
#echo $srcpath
CUR_SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)
echo "script dir: ${SCRIPT_DIR}"
#################################################


#################################################
#Set Qt configuration option variables
QT_BUILD_VERSION=6.8.0.0
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."

QT_BUILD_PATH="/build/${CONFIG_TYPE_PARAM}"
QT_INSTALL_PATH="/out/${CONFIG_TYPE_PARAM}"
QT_3RDPARTY_PATH="${CUR_BAT_PATH}/3rdParty"

#Set CONFIG_PREFIX="${QT_ROOT_PATH}/qtbase"
CONFIG_PREFIX=${QT_INSTALL_PATH}
CONFIG_EXT_PREFIX=${QT_INSTALL_PATH}

# Remove the installation folder first
if  [  -d  "${QT_BUILD_PATH}"  ]; then
	rm -rf "${QT_BUILD_PATH}"
fi
mkdir -p $QT_BUILD_PATH

if  [  -d  "${QT_INSTALL_PATH}"  ]; then
	rm -rf "${QT_INSTALL_PATH}"
fi
mkdir -p $QT_INSTALL_PATH

#################################################
# GPL MODULE EXCLUSION CONFIGURATION
#################################################
# To avoid GPL binaries, the following modules are excluded:
# - qtvirtualkeyboard: Virtual keyboard components (GPL)
# - qtquicktimeline: Timeline animations (GPL)
# - qtquick3d: 3D graphics and physics (GPL)
# - qtquick3dphysics: 3D physics engine (GPL)
# - qtcharts: Charting components (GPL)
# - qtdatavis3d: 3D data visualization (GPL)
# - qtnetworkauth: Network authentication (GPL)
# - qtlottie: Lottie animation support (GPL)
# - qtcoap: CoAP protocol support (GPL)
# - qtmqtt: MQTT protocol support (GPL)
# - qtgraphs: Graph visualization (GPL)
#
# Additional configuration options:
# - -no-feature-designer: Disables Qt Designer (GPL components)
#
# The modules in QT_MODULE_EXCLUDED will be excluded from git syncing (GPL modules)
QT_MODULE_EXCLUDED=-qtlocation,-qtvirtualkeyboard,-qtquicktimeline,-qtquick3d,-qtnetworkauth,-qtdatavis3d,-qtcharts,\
-qtquick3dphysics,-qtlottie,-qtcoap,-qtmqtt,-qtwayland,-qtgraphs

# The modules in QT_MODULE_SKIPPED will be skipped from building (GPL modules)
# Complete list of GPL modules to skip during build
QT_MODULE_SKIPPED=" -skip qtlocation -skip qtvirtualkeyboard -skip qtquicktimeline -skip qtquick3d -skip qtnetworkauth \
                   -skip qtdatavis3d -skip qtcharts -skip qtquick3dphysics \
                   -skip qtlottie -skip qtcoap -skip qtmqtt -skip qtwayland -skip qtgraphs -skip qtopcua "

echo QT_ROOT_PATH:$QT_ROOT_PATH
echo CUR_SCRIPT_PATH:$CUR_SCRIPT_PATH
pwd

#Enter the Qt root directory
cd ${QT_ROOT_PATH}
pwd

#################################################
#Git init and sync

#Initialize the repository
perl init-repository --force --module-subset=default,${QT_MODULE_EXCLUDED}

#Sync the submoudles url, maybe it's not necessary
git submodule sync

#Submodule update
git submodule update --init --recursive
#################################################

#################################################
#Configure the Qt options 
echo "begin to configure"

pushd $QT_BUILD_PATH
ls $QT_BUILD_PATH

df -h

if [[ "${CONFIG_TYPE_PARAM}" == "debug" ]]; then
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -icu -opengl desktop -sql-psql \
                          -openssl-runtime -qt-libjpeg -qt-zlib -qt-harfbuzz -qt-freetype -qt-doubleconversion -xcb -debug -force-debug-info -separate-debug-info \
                          -nomake \examples -nomake tests -no-warnings-are-errors \
                          -no-feature-designer \
                          ${QT_MODULE_SKIPPED} \
                          -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR} -DFEATURE_webengine_jumbo_build=off -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS_DEBUG="-g -Os" --log-level=STATUS \
                          2>&1 | tee ${CUR_SCRIPT_PATH}/Qt.Configureation.Debug.Summary.txt
else
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -icu -opengl desktop -sql-psql \
                            -openssl-runtime -qt-libjpeg -qt-zlib -qt-harfbuzz -qt-freetype -qt-doubleconversion -xcb -release -force-debug-info -separate-debug-info \
                            -nomake examples -nomake tests -no-warnings-are-errors \
                            -no-feature-designer \
                            ${QT_MODULE_SKIPPED} \
                            -- -DCMAKE_PREFIX_PATH=${LLVM_INSTALL_DIR} -DFEATURE_webengine_jumbo_build=off -DCMAKE_BUILD_TYPE=RelWithDebInfo --log-level=STATUS \
                            2>&1 | tee ${CUR_SCRIPT_PATH}/Qt.Configuration.Release.Summary.txt
fi

popd
echo "Configure '$CONFIG_TYPE_PARAM' build complete!"
#################################################


#################################################
echo "begin to build '${CONFIG_TYPE_PARAM}' version ..."
pushd $QT_BUILD_PATH

error_code=1
${CMAKE_TOOL} --build . -j2 || exit 1

result=$(find . -type f -iname "libQt6WebEngineCore*")
if [[ -n "$result" ]]; then
  error_code=$? 
else
  error_code=1
fi
popd

if [[ ${error_code} -ne 0 ]]; then
  #if there is something wrong, print out the system log
  dmesg
  echo error_code:$error_code

  exit ${error_code}
fi

echo "Complete the build for '${CONFIG_TYPE_PARAM}' version"
#################################################

#################################################
echo "begin to install ..."

pushd $QT_BUILD_PATH
ninja install || exit 1
popd

echo "Complete the install"
#################################################


#################################################
# Copy some corresponding files to the Compilers folder

# for k in $(seq 1 $number); do echo $k; donefor ()
for BUILD_PATH in ${QT_INSTALL_PATH}
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
    if [ -e "${BUILD_PATH}/libexec/qtmoc" ]; then
      cp -rf ${BUILD_PATH}/libexec/qtmoc ${QT_INSTALL_COMPILER_PATH}
    fi

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

# copy the icu related binaries to lib folder
QT_INSTALL_LIB_PATH=${BUILD_PATH}/lib
cp -rP /usr/lib64/libicu* ${QT_INSTALL_LIB_PATH}

#################################################
echo Building is done. You should check whether there exist errors.
df -h
#################################################
