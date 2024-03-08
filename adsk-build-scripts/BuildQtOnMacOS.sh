#!/bin/sh
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
CUR_SCRIPT_PATH=`(cd "$srcpath"; pwd)`
#################################################


#################################################
#Set Qt configuration option variables
QT_BUILD_VERSION=6.5.3.0
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."

QT_BUILD_DEBUG_ENABLED=0
QT_BUILD_RELEASE_ENABLED=1

QT_BUILD_PATH_DEBUG="$QT_ROOT_PATH/../qt-build-debug"
QT_BUILD_PATH_RELEASE="$QT_ROOT_PATH/../qt-build-release"

# QT_INSTALL_PATH="$QT_ROOT_PATH/../qt_macOS_opensource_universal.6.5.3.0"
# QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/../qt_macOS_opensource_universal_${QT_BUILD_VERSION}_debug"
QT_INSTALL_PATH_DEBUG="$QT_ROOT_PATH/../qt_macOS_opensource_universal_debug"
# QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/../qt_macOS_opensource_universal_${QT_BUILD_VERSION}_release"
QT_INSTALL_PATH_RELEASE="$QT_ROOT_PATH/../qt_macOS_opensource_universal_release"

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

#The modules in QT_MODULE_EXCLUDED will be excluded from git syncing
#set QT_MODULE_EXCLUDED="-preview,-qtnetworkauth,-qtpurchasing,-qtquick3d,-qtlottie,-qtcharts,-qtdatavis3d,-qtvirtualkeyboard,-qtwebglplugin,-qtactiveqt,-qtconnectivity,-qtcoap,-qtmqtt,-qtopcua,-qtquicktimeline,-qtquickeffectmaker,-qtquick3dphysics"
QT_MODULE_EXCLUDED=-qtlocation,-qtvirtualkeyboard,-qtquicktimeline,-qtquick3d,-qtnetworkauth,-qtdatavis3d,-qtcharts,\
-qtquick3d,-qtquick3dphysics,-qtlottie,-qtcoap,-qtmqtt

#The modules in QT_MODULE_SKIPPED will be skipped from building
#QT_MODULE_SKIPPED=" -skip qtlocation "
QT_MODULE_SKIPPED=" -skip qtlocation -skip qtvirtualkeyboard -skip qtquicktimeline -skip qtquick3d -skip qtnetworkauth \
                   -skip qtdatavis3d -skip qtcharts -skip qtquick3d -skip qtquick3dphysics \
                   -skip qtlottie -skip qtcoap -skip qtmqtt "

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
  mkdir $QT_BUILD_PATH_RELEASE
  #cd ../qt-build-release
  pushd $QT_BUILD_PATH_RELEASE
  pwd
  ls $QT_BUILD_PATH_RELEASE
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_RELEASE} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql \
              -openssl-runtime -qt-libjpeg -qt-zlib -release -force-debug-info -separate-debug-info \
              -nomake examples -nomake tests -no-warnings-are-errors \
              ${QT_MODULE_SKIPPED} \
              -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0"
  popd
fi

#Configuration for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf $QT_BUILD_PATH_DEBUG
  rm -rf ${CONFIG_PREFIX_DEBUG}

  #mkdir ../qt-build-debug
  mkdir $QT_BUILD_PATH_DEBUG
  pushd $QT_BUILD_PATH_DEBUG
  pwd
  ls $QT_BUILD_PATH_DEBUG
  ${QT_ROOT_PATH}/configure -opensource -confirm-license -prefix ${CONFIG_PREFIX_DEBUG} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql \
              -openssl-runtime -qt-libjpeg -qt-zlib -debug -force-debug-info -separate-debug-info \
              -nomake examples -nomake tests -no-warnings-are-errors \
              ${QT_MODULE_SKIPPED} \
              -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0"
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
  cmake --build . --parallel
  popd
fi

#Build for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  pushd $QT_BUILD_PATH_DEBUG
  cmake   --build . --parallel
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
  ninja install
  popd
fi

#Installation for debug version
if [ $QT_BUILD_DEBUG_ENABLED -eq 1 ]; then
  #Remove the previous folders
  rm -rf ${CONFIG_PREFIX_DEBUG}

  pushd $QT_BUILD_PATH_DEBUG
  ninja install
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
echo Building is done. You should check whether there exist errors.
#################################################
