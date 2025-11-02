#!/bin/sh

export PATH="/Applications/CMake.app/Contents/bin:$PATH"
export PATH="/usr/local/opt/node@20/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

#################################################
#@file BuildQtOnMacOS.sh
#@brief Build script for Qt 6.5.3 universal version on macOS
#@team FARA/CM (Consistant Material scrum team)
#@author Huimin Wen(Jess)
#@email huimin.wen@autodesk.com
#@date 1/16/2022
#################################################


#################################################
#Common Functions
have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]
  then
    return 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]
  then
    SUDO+=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]
  then
    SUDO+=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]
  then
    if [[ -n "${NONINTERACTIVE-}" ]]
    then
      "${SUDO[@]}" -l mkdir &>/dev/null
    else
      "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -z "${HOMEBREW_ON_LINUX-}" ]] && [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]
  then
    abort "Need sudo access on macOS (e.g. the user ${USER} needs to be an Administrator)!"
  fi

  return "${HAVE_SUDO_ACCESS}"
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

execute() {
  if ! "$@"
  then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

#################################################


#################################################
#Set options for this shell script
#srcpath=`dirname $0`
#srcpath=`(cd "$srcpath"; pwd)`
#echo $srcpath
CUR_SCRIPT_PATH=`dirname $0`
#################################################

#################################################
#Set Qt configuration option variables
QT_BUILD_VERSION=6.8.0.0
QT_ROOT_PATH=`pwd`

QT_BUILD_DEBUG_ENABLED=0
QT_BUILD_RELEASE_ENABLED=1

QT_BUILD_PATH_DEBUG="$QT_ROOT_PATH/_Build/debug"
QT_BUILD_PATH_RELEASE="$QT_ROOT_PATH/_Build/release"

# QT_INSTALL_PATH="$QT_ROOT_PATH/../qt_macOS_opensource_universal.6.5.3.0"
QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/Build/qt5.mac/debug"
QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/Build/qt5.mac/release"

QT_3RDPARTY_PATH="${CUR_BAT_PATH}/3rdParty"

#Set CONFIG_PREFIX="${QT_ROOT_PATH}/qtbase"
#CONFIG_PREFIX=$QT_INSTALL_PATH
CONFIG_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

#CONFIG_EXT_PREFIX=$QT_INSTALL_PATH
CONFIG_EXT_PREFIX_DEBUG=$QT_INSTALL_PATH_DEBUG
CONFIG_EXT_PREFIX_RELEASE=$QT_INSTALL_PATH_RELEASE

# Remove the installation folder first
if  [  -d  "${QT_INSTALL_PATH_DEBUG}"  ]; then
	rm -rf "${QT_INSTALL_PATH_DEBUG}"
fi

if  [  -d  "${QT_INSTALL_PATH_RELEASE}"  ]; then
	rm -rf "${QT_INSTALL_PATH_RELEASE}"
fi

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
-qtquick3dphysics,-qtlottie,-qtcoap,-qtmqtt,-qtgraphs

# The modules in QT_MODULE_SKIPPED will be skipped from building (GPL modules)
# Complete list of GPL modules to skip during build
QT_MODULE_SKIPPED=" -skip qtlocation -skip qtvirtualkeyboard -skip qtquicktimeline -skip qtquick3d -skip qtnetworkauth \
                   -skip qtdatavis3d -skip qtcharts -skip qtquick3dphysics \
                   -skip qtlottie -skip qtcoap -skip qtmqtt -skip qtgraphs"

export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl@3.0/3.0.18
export PostgreSQL_ROOT=/Applications/Postgres.app/Contents/Versions/18
# export LLVM_INSTALL_DIR=/Volumes/DATA/Qt6/CommonTools/libclang  # Commented out to prevent clangcpp feature from being enabled

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
#Configuraion for release version
if [ $QT_BUILD_RELEASE_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf $QT_BUILD_PATH_RELEASE
  rm -rf ${CONFIG_PREFIX_RELEASE}

  #mkdir ../qt-build-release
  mkdir -p $QT_BUILD_PATH_RELEASE
  #cd ../qt-build-release
  pushd $QT_BUILD_PATH_RELEASE
  pwd
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_RELEASE} -opengl desktop -sql-psql \
              -openssl-runtime -qt-libjpeg -qt-zlib -release -force-debug-info -separate-debug-info \
              -nomake examples -nomake tests -no-warnings-are-errors -DFEATURE_clangcpp=OFF \
              -no-feature-designer \
              ${QT_MODULE_SKIPPED} \
              -- -G "Ninja" -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET="14.0" -DCMAKE_INSTALL_RPATH="@executable_path/../Frameworks" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON || exit 1
  popd
fi

#Configuration for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf $QT_BUILD_PATH_DEBUG
  rm -rf ${CONFIG_PREFIX_DEBUG}

  #mkdir ../qt-build-debug
  mkdir -p $QT_BUILD_PATH_DEBUG
  pushd $QT_BUILD_PATH_DEBUG
  pwd
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_DEBUG} -opengl desktop -sql-psql \
              -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info \
              -nomake examples -nomake tests -no-warnings-are-errors -DFEATURE_clangcpp=OFF \
              -no-feature-designer \
              ${QT_MODULE_SKIPPED} \
              -- -G "Ninja" -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET="14.0" -DCMAKE_INSTALL_RPATH="@executable_path/../Frameworks" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON || exit 1
  popd
fi
#################################################
#exit


#################################################
#Build Qt with the configuration options
#cmake --build . --parallel

#Build for release version
if [ $QT_BUILD_RELEASE_ENABLED -eq 1 ]; then
  pushd $QT_BUILD_PATH_RELEASE
  cmake --build . --parallel || exit 1
  popd
fi

#Build for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  pushd $QT_BUILD_PATH_DEBUG
  cmake   --build . --parallel || exit 1
  popd
fi
#################################################
#exit


#################################################
#Install Qt build output to the directory of prefix option
#cmake --install .
#ninja install

#Installation for release version
if [ $QT_BUILD_RELEASE_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf ${CONFIG_PREFIX_RELEASE}

  pushd $QT_BUILD_PATH_RELEASE
  ninja install || exit 1
  popd
fi

#Installation for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf ${CONFIG_PREFIX_DEBUG}

  pushd $QT_BUILD_PATH_DEBUG
  ninja install || exit 1
  popd
fi
#################################################


#################################################
#Delete all "*-debug.cmake" files
#pushd ${QT_INSTALL_PATH}
pushd ${QT_INSTALL_PATH_RELEASE}
find ./lib/cmake -type f -name "*-debug.cmake" -delete

#Delete all "*_debug" files
find . -type f -name "*_debug" -delete
find . -type l -name "*_debug" -delete
popd 
#################################################

#################################################
# Copy some corresponding files to the Compilers folder
  QT_INSTALL_COMPILER_PATH=${CONFIG_PREFIX_RELEASE}/compilers
  if  [  -d  "${QT_INSTALL_COMPILER_PATH}"  ]; then
	  rm -rf "${QT_INSTALL_COMPILER_PATH}"
  fi
  mkdir -p $QT_INSTALL_COMPILER_PATH

  cp $CONFIG_PREFIX_RELEASE/bin/lconvert $QT_INSTALL_COMPILER_PATH/lconvert
	cp $CONFIG_PREFIX_RELEASE/bin/lrelease $QT_INSTALL_COMPILER_PATH/lrelease
	cp $CONFIG_PREFIX_RELEASE/libexec/lupdate-pro $QT_INSTALL_COMPILER_PATH/lupdate-pro
	cp $CONFIG_PREFIX_RELEASE/libexec/lprodump $QT_INSTALL_COMPILER_PATH/lprodump
	cp $CONFIG_PREFIX_RELEASE/libexec/qmlcachegen $QT_INSTALL_COMPILER_PATH/qmlcachegen
	cp $CONFIG_PREFIX_RELEASE/bin/lupdate $QT_INSTALL_COMPILER_PATH/lupdate
	cp $CONFIG_PREFIX_RELEASE/libexec/moc $QT_INSTALL_COMPILER_PATH/moc
	cp $CONFIG_PREFIX_RELEASE/bin/qmake $QT_INSTALL_COMPILER_PATH/qmake
	cp $CONFIG_PREFIX_RELEASE/libexec/rcc $QT_INSTALL_COMPILER_PATH/rcc
	cp $CONFIG_PREFIX_RELEASE/libexec/uic $QT_INSTALL_COMPILER_PATH/uic
	cp -R $CONFIG_PREFIX_RELEASE/lib/QtCore.framework $QT_INSTALL_COMPILER_PATH/QtCore.framework
	cp -R $CONFIG_PREFIX_RELEASE/lib/QtXml.framework $QT_INSTALL_COMPILER_PATH/QtXml.framework
	cp -R $CONFIG_PREFIX_RELEASE/lib/QtQml.framework $QT_INSTALL_COMPILER_PATH/QtQml.framework
	cp -R $CONFIG_PREFIX_RELEASE/lib/QtNetwork.framework $QT_INSTALL_COMPILER_PATH/QtNetwork.framework

	cp $CONFIG_PREFIX_RELEASE/libexec/tracegen $QT_INSTALL_COMPILER_PATH/tracegen
	cp $CONFIG_PREFIX_RELEASE/libexec/cmake_automoc_parser $QT_INSTALL_COMPILER_PATH/cmake_automoc_parser
	cp $CONFIG_PREFIX_RELEASE/libexec/qlalr $QT_INSTALL_COMPILER_PATH/qlalr
	cp $CONFIG_PREFIX_RELEASE/bin/qtpaths $QT_INSTALL_COMPILER_PATH/qtpaths
	cp $CONFIG_PREFIX_RELEASE/bin/androiddeployqt $QT_INSTALL_COMPILER_PATH/androiddeployqt
	cp $CONFIG_PREFIX_RELEASE/bin/androidtestrunner $QT_INSTALL_COMPILER_PATH/androidtestrunner
	cp $CONFIG_PREFIX_RELEASE/libexec/qvkgen $QT_INSTALL_COMPILER_PATH/qvkgen
	cp $CONFIG_PREFIX_RELEASE/libexec/qmltyperegistrar $QT_INSTALL_COMPILER_PATH/qmltyperegistrar
	cp $CONFIG_PREFIX_RELEASE/bin/qmldom $QT_INSTALL_COMPILER_PATH/qmldom
	cp $CONFIG_PREFIX_RELEASE/bin/qmllint $QT_INSTALL_COMPILER_PATH/qmllint
	cp $CONFIG_PREFIX_RELEASE/libexec/qmlimportscanner $QT_INSTALL_COMPILER_PATH/qmlimportscanner
	cp $CONFIG_PREFIX_RELEASE/bin/qmlformat $QT_INSTALL_COMPILER_PATH/qmlformat
	cp $CONFIG_PREFIX_RELEASE/bin/qml $QT_INSTALL_COMPILER_PATH/qml
	cp $CONFIG_PREFIX_RELEASE/bin/qmlprofiler $QT_INSTALL_COMPILER_PATH/qmlprofiler
	cp $CONFIG_PREFIX_RELEASE/bin/qmlpreview $QT_INSTALL_COMPILER_PATH/qmlpreview

  cp $CONFIG_PREFIX_RELEASE/bin/qmlscene $QT_INSTALL_COMPILER_PATH/qmlscene
	cp $CONFIG_PREFIX_RELEASE/bin/qmltime $QT_INSTALL_COMPILER_PATH/qmltime
	cp $CONFIG_PREFIX_RELEASE/bin/qmlplugindump $QT_INSTALL_COMPILER_PATH/qmlplugindump
	cp $CONFIG_PREFIX_RELEASE/bin/qmltestrunner $QT_INSTALL_COMPILER_PATH/qmltestrunner
	cp $CONFIG_PREFIX_RELEASE/libexec/qwebengine_convert_dict $QT_INSTALL_COMPILER_PATH/qwebengine_convert_dict

  pushd $QT_INSTALL_COMPILER_PATH
  install_name_tool -add_rpath @loader_path lconvert
	install_name_tool -add_rpath @loader_path lrelease
  install_name_tool -add_rpath @loader_path lupdate-pro
  install_name_tool -add_rpath @loader_path lprodump
  install_name_tool -add_rpath @loader_path qmlcachegen
	install_name_tool -add_rpath @loader_path lupdate
  install_name_tool -add_rpath @loader_path moc
	install_name_tool -add_rpath @loader_path qmake
	install_name_tool -add_rpath @loader_path rcc
	install_name_tool -add_rpath @loader_path uic
  install_name_tool -add_rpath @loader_path tracegen
  install_name_tool -add_rpath @loader_path cmake_automoc_parser
  install_name_tool -add_rpath @loader_path qlalr
  install_name_tool -add_rpath @loader_path qtpaths
  install_name_tool -add_rpath @loader_path androiddeployqt
  install_name_tool -add_rpath @loader_path androidtestrunner
  install_name_tool -add_rpath @loader_path qvkgen
  install_name_tool -add_rpath @loader_path qmltyperegistrar
  install_name_tool -add_rpath @loader_path qmldom
  install_name_tool -add_rpath @loader_path qmllint
  install_name_tool -add_rpath @loader_path qmlimportscanner
  install_name_tool -add_rpath @loader_path qmlformat
  install_name_tool -add_rpath @loader_path qml
  install_name_tool -add_rpath @loader_path qmlprofiler
  install_name_tool -add_rpath @loader_path qmlpreview
  install_name_tool -add_rpath @loader_path qmlscene
  install_name_tool -add_rpath @loader_path qmltime
  install_name_tool -add_rpath @loader_path qmlplugindump
  install_name_tool -add_rpath @loader_path qmltestrunner
  install_name_tool -add_rpath @loader_path qwebengine_convert_dict
  popd

#################################################
echo Building is done. You should check whether there exist errors.
#################################################
