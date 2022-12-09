#!/bin/sh
#################################################
#@file BuildQtOnMacOS.sh
#@brief Build script for Qt 6.2.4 universal version on macOS
#@team FARA/CM (Consistant Material scrum team)                 
#@author Huimin Wen(Jess)                                                             
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
QT_ROOT_PATH="$CUR_SCRIPT_PATH/.."
QT_INSTALL_PATH="$QT_ROOT_PATH/../qt_macOS_universal_opensource_v140.6.2.4.0"
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
./configure -opensource -confirm-license -prefix ${CONFIG_PREFIX} -opengl desktop -plugin-sql-sqlite -sql-psql -plugin-sql-psql -openssl-runtime -qt-libjpeg -qt-zlib -debug-and-release -force-debug-info -nomake examples -nomake tests -no-warnings-are-errors ${QT_MODULE_SKIPPED} -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
#################################################


#################################################
#Build Qt with the configuration options
cmake --build . --parallel
#################################################


#################################################
#Install Qt build output to the directory of prefix option
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
