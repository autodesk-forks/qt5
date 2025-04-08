#!/usr/bin/env bash

set -e # Terminate with failure if any command returns nonzero
set -u # Terminate with failure any time an undefined variable is expanded

SCRIPT_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" >/dev/null 2>&1 && pwd)"

echo -n "Start timestamp: "; date

isMacOS=0
isLinux=0
isWin=0
case $OSTYPE in
  darwin*)
    isMacOS=1
    ;;
  linux*)
    isLinux=1
    ;;
  msys*|cygwin*)
    isWin=1
    echo >&2 "error: Windows builds using this script is not supported yet"
    # Need a way to source vcvarsall.
    exit 1
    ;;
  *)
    echo >&2 "error: running on unknown OS"
    exit 1
esac

# Parameter 1 - Absolute path to workspace directory
if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
    exit 1
fi

# Process command line arguments.
# Location of the workspace directory (root of the folder structure)
export WORKSPACE_DIR=$(readlink -f $1)
shift

DO_CONFIGURE=1
DO_BUILD=1
DO_INSTALL=1
GUESS_QTVERSION=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--build)
      DO_CONFIGURE=
      DO_INSTALL=
      shift
      ;;
    -i|--install)
      DO_CONFIGURE=
      DO_BUILD=
      shift
      ;;
    -z)
      DO_CONFIGURE=
      DO_BUILD=
      DO_INSTALL=
      ARGS+=("$1") # save arg
      shift
      ;;
    -g|--guess-version)
      GUESS_QTVERSION=1
      QTVERSION=""
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      ARGS+=("$1") # save arg
      shift
      ;;
  esac
done
set -- "${ARGS[@]: }" # restore args

set +u
# Environment Variable - QTVERSION - Version of Qt to build
if [[ -z "$GUESS_QTVERSION" && -z "${QTVERSION}" ]]; then
    echo "QTVERSION is undefined. Example: export QTVERSION=6.8.3"
    exit 1
else
    echo "QTVERSION=${QTVERSION}"
fi
set -u

# Location where the final build will be located, as defined by the -prefix option
export INSTALL_DIR=$WORKSPACE_DIR/install/qt_$QTVERSION
export BUILD_DIR=$WORKSPACE_DIR/build

# Location of the source code directory (top of git tree - qt5.git)
export SOURCE_DIR=$(readlink -f "$SCRIPT_DIR/..")

export PYTHON_DIR=""
set +u
if [[ $isMacOS -eq 1 ]]; then
    # Maya Python artifact has the Python.framework compressed into a tarball
    # for some reason. Maya expects this. We need to expand it to be able to use
    # it. PYTHONEXE should be a path into this expanded tarball, which is why we
    # do the expansion before the next python checks.
    export python_frameworks_dir="$(dirname $PYTHONEXE)/../../../.."
    export python_framework_tarball="${python_frameworks_dir}/Python.framework.tar.gz"
    if [[ -f "${python_framework_tarball}" ]]; then
        tar -C "${python_frameworks_dir}" -xvf "${python_framework_tarball}"
        rm "${python_framework_tarball}"
    fi
fi

if [[ ! -x "$PYTHONEXE" ]]; then
    if [[ -z "$PYTHONEXE" ]]; then
        echo >&2 "PYTHONEXE is undefined."
    elif [[ ! -e "$PYTHONEXE" ]]; then
        echo >&2 "PYTHONEXE ${PYTHONEXE} doesn't exist."
    elif [[ ! -x "$PYTHONEXE" ]]; then
        echo >&2 "PYTHONEXE ${PYTHONEXE} isn't executable."
    fi
    echo >&2 "Example: export PYTHONEXE=${WORKSPACE_DIR}/external_dependencies/cpython/3.11.4/RelWithDebInfo/bin/python3.11"
    exit 1
else
    # make python symlinks: python, python3
    export PYTHON_DIR=$(dirname $PYTHONEXE)
    for py_link in "python3" "python"; do
        if [[ ! -e "$PYTHON_DIR/$py_link" ]]; then
            ln -s $(basename "$PYTHONEXE") "$PYTHON_DIR/$py_link"
            echo "Symlink $PYTHON_DIR/$py_link made"
        fi
    done
    echo "PYTHONEXE=${PYTHONEXE}"
fi
set -u

export OPENSSL_BIN_DIR=""
export OPENSSL_LIB_DIR=""
export LLVM_INSTALL_DIR=""
if [[ $isMacOS -eq 1 ]]; then
    export CMAKE_DIR=$WORKSPACE_DIR/external_dependencies/cmake-3.26.0-macos-universal/CMake.app/Contents
    export NINJA_DIR=$WORKSPACE_DIR/external_dependencies/ninja
    export NODE_DIR=$WORKSPACE_DIR/external_dependencies/node-v16.14.0-darwin-x64
elif [[ $isLinux -eq 1 ]]; then
    # Location of openssl include directory (optional) within the external dependencies directory
    # Update with artifact build of recent OpenSSL release when available.
    # ... and add -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR to configure line below. (?)
    # Maya includes a newer version of OpenSSL - which Qt will take into use.
    export OPENSSL_ROOT_DIR="$WORKSPACE_DIR/external_dependencies/openssl"
    export OPENSSL_BIN_DIR="$OPENSSL_ROOT_DIR/bin"
    export OPENSSL_LIB_DIR="$OPENSSL_ROOT_DIR/lib"    
    export CMAKE_DIR=$WORKSPACE_DIR/external_dependencies/cmake-3.26.0-linux-x86_64
    export NINJA_DIR=$WORKSPACE_DIR/external_dependencies/ninja
    export NODE_DIR=$WORKSPACE_DIR/external_dependencies/node-v16.14.0-linux-x64
    export LLVM_INSTALL_DIR="$WORKSPACE_DIR/external_dependencies/libclang/lib/cmake"
    export LD_LIBRARY_PATH=$OPENSSL_LIB_DIR:$LD_LIBRARY_PATH
fi
export PATH=$OPENSSL_BIN_DIR:$CMAKE_DIR/bin:$NINJA_DIR:$NODE_DIR/bin:$PYTHON_DIR:$PATH

echo "PATH=$PATH"


if [[ ! "${QTVERSION}" =~ [0-9]\.[0-9]+\.[0-9]* ]]; then
    set +e
    python --version >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        if [[ -n "$GUESS_QTVERSION" ]]; then
            echo >&2 "Python non-functional, cannot guess QTVERSON."
        else
            echo >&2 "QTVERSION is not a version number. Example: export QTVERSION=6.8.3"
        fi
        exit 1
    fi
    set -e
    if [[ -z "$GUESS_QTVERSION" ]]; then
        echo -n "QTVERSION is not a version number. "
    fi
    echo "Figuring out Qt version from the codebase..."
    QTVERSION=$(python $SCRIPT_DIR/fetch-qt-version.py ${SOURCE_DIR})
    echo "QTVERSION=$QTVERSION"
fi

# Print compiler info, Python, patchelf (linux), cmake, ninja, nodejs, and openssl (when used) versions
set +e
patchelf_ret=0
openssl_ret=0
if [[ $isMacOS -eq 1 ]]; then
    xcodebuild -version
    compiler_ret=$?
elif [[ $isLinux -eq 1 ]]; then
    gcc --version | head -1
    gcc --version >/dev/null 2>&1
    compiler_ret=$?

    patchelf --version
    patchelf_ret=$?
fi
if [[ $isLinux -eq 1 || $isWin -eq 1 ]]; then
    openssl version
    openssl_ret=$?
fi
python --version
python_ret=$?
cmake --version | head -1
echo -n "ninja "
ninja --version
ninja_ret=$?
echo -n "node "
node --version
node_ret=$?
set -e

if [ $compiler_ret -ne 0 ]; then
    echo "Compiler (xcode, gcc, msvc) not present. Aborting."
    exit 1
fi

# Only applies to Windows and Linux
if [ $openssl_ret -ne 0 ]; then
    echo "OpenSSL not present. Aborting."
    exit 1
fi

if [ $python_ret -ne 0 ]; then
    echo "python not present. Aborting."
    exit 1
fi

# Only applies to Linux
if [ $patchelf_ret -ne 0 ]; then
    echo "patchelf not present. Aborting."
    exit 1
fi

set +e
cmake --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "cmake not present. Aborting."
    exit 1
fi
set -e

if [ $ninja_ret -ne 0 ]; then
    echo "ninja not present. Aborting."
    exit 1
fi

if [ $node_ret -ne 0 ]; then
    echo "nodejs not present. Aborting."
    exit 1
fi

function installPythonPackage()
{
    set +e
    lib_name=$1
    lib_installed=$(python -m pip list installed 2>/dev/null | grep $lib_name | wc -l)
    if [ $lib_installed -eq 0 ]; then
        echo "python $lib_name not installed. Installing it."
        python -m pip install --no-input $lib_name
        if [[ $? -ne 0 ]]; then
            echo "Install of python $lib_name failed. aborting."
            exit 1
        fi
    fi
    python -m pip list installed 2>/dev/null | sed -e "/$lib_name/!d;s/[[:space:]][[:space:]]*/ /g"
    set -e
}

installPythonPackage "webencodings"
installPythonPackage "html5lib"

function exitIfFailed
{

  # $1 return code of command
  # $2 Last operation string

  if [ $1 -ne 0 ]; then
    echo "***** Failed to ${2} *****"
    exit 1
  fi
  return 0
}

if [[ -n "$DO_CONFIGURE" && -e "$BUILD_DIR" ]]; then
    echo >&2 "Build dir $BUILD_DIR already exists. This is unexpected."
    echo >&2 "Removing $BUILD_DIR."
    rm -Rf "$BUILD_DIR"
    if [[ $? -ne 0 ]]; then
        echo >&2 "Failed to remove $BUILD_DIR. aborting."
        exit 1
    fi
fi

set -e
if [[ ! -e "$BUILD_DIR" ]]; then
    mkdir "$BUILD_DIR"
fi
BUILD_DIR=$(cd "${BUILD_DIR}" && pwd -P)
cd "$BUILD_DIR"
echo -n "BUILD_DIR PWD == "
pwd
set +e

CONFIGURE_RETURNCODE=0
if [ -n "$DO_CONFIGURE" ]; then
    # Configure the build
    # Configure options: https://wiki.qt.io/Qt_6.8_Tools_and_Versions
    # coin/platform_configs/cmake_platforms.yaml

    # Define the modules to skip (because they are under commercial license)
    export COMMERCIAL_MODULES_TO_SKIP="-skip qtcharts -skip qtdatavis3d "\
"-skip qtlottie -skip qtmqtt -skip qtnetworkauth -skip qtquick3d "\
"-skip qtquicktimeline -skip qtvirtualkeyboard"
    export MODULES_TO_SKIP="${COMMERCIAL_MODULES_TO_SKIP} -skip qtconnectivity -skip qtgraphs"\
" -skip qtcoap -skip qtopcua -skip qtpdf -skip qtquick3dphysics -skip qtquickeffectmaker"

    PLAT_ARGS=""
    PLAT_CMAKE_DEFS=""
    if [[ $isMacOS -eq 1 ]]; then
        PLAT_ARGS="-debug-and-release -no-strip"
        MODULES_TO_SKIP="${MODULES_TO_SKIP} -skip qtwayland"
        #PLAT_CMAKE_DEFS='-DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0'
        $SOURCE_DIR/configure -opensource -confirm-license -prefix $INSTALL_DIR\
 -nomake tests -nomake examples -force-debug-info -separate-debug-info -opengl \
desktop -feature-qtwebengine-build $PLAT_ARGS \
$MODULES_TO_SKIP -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 -DQT_FORCE_WARN_APPLE_SDK_AND_XCODE_CHECK=ON
        CONFIGURE_RETURNCODE=$?
    elif [[ $isLinux -eq 1 ]]; then
        # https://cmake.org/cmake/help/latest/module/FindOpenGL.html
        PLAT_ARGS="-release -qt-libjpeg -qt-libpng -qt-pcre -qt-harfbuzz -no-feature-wayland-server "\
"-qt-doubleconversion -no-libudev -bundled-xcb-xinput -sysconfdir /etc/xdg "\
"-R . -icu -qt-qt3d-assimp -openssl-runtime"
        PLAT_CMAKE_DEFS="-DOpenGL_GL_PREFERENCE=LEGACY -DLLVM_INSTALL_DIR=$LLVM_INSTALL_DIR"
    elif [[ $isWin -eq 1 ]]; then
        MODULES_TO_SKIP="${MODULES_TO_SKIP} -skip qtwayland"
        PLAT_ARGS="-debug-and-release -optimized-tools -openssl-runtime "\
"-qt-zlib"
        PLAT_CMAKE_DEFS="-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR"
    fi

    if [[ $isMacOS -ne 1 ]]; then
        $SOURCE_DIR/configure -opensource -confirm-license -prefix $INSTALL_DIR\
 -nomake tests -nomake examples -force-debug-info -separate-debug-info -opengl \
desktop -feature-qtwebengine-build $PLAT_ARGS \
$MODULES_TO_SKIP -- $PLAT_CMAKE_DEFS
        CONFIGURE_RETURNCODE=$?
    fi
    echo -n "End Configure timestamp: "; date
fi

BUILD_RETURNCODE=0
if [ -n "$DO_BUILD" -a $CONFIGURE_RETURNCODE -eq 0 ]; then
    # pass `-- -v` to make ninja verbose
    echo "Building Qt..."
    cmake --build . --parallel
    BUILD_RETURNCODE=$?
    echo -n "End Build timestamp: "; date
fi

INSTALL_RETURNCODE=0
COMPRESS_RETURNCODE=0
if [ -n "$DO_INSTALL" -a $BUILD_RETURNCODE -eq 0 ]; then
    cmake --install .
    INSTALL_RETURNCODE=$?
    echo -n "End cmake install timestamp: "; date
    if [ $INSTALL_RETURNCODE -eq 0 ]; then
        set -e
        cd $INSTALL_DIR
        if [[ $isMacOS -eq 1 ]]; then
            # Generate and compress debug symbols in install directory
            # Find all dylib files that are not symlinks or Webengine/webview libs
            # Skip the webengine debug symbols because they are incredibly heavy,
            # more than half of the artifact.

            dsyms=$(find . -name "*.dSYM" -a -not -type l)
            web_dsyms=$(find . -name "QtWeb*.dSYM" -a -not -type l)
            no_web_dsyms=$(printf "%s\n" "${dsyms[@]}" "${web_dsyms[@]}" "${web_dsyms[@]}" | sort | uniq -u)
            for dSYM in $no_web_dsyms; do
                echo "Creating $dSYM.tgz compressed debug symbols."
                if [[ ! -d "$dSYM" ]]; then
                    echo >&2 "WARNING: dSYM $dSYM was never generated."
                    exit 1
                fi
                tar -czf "${dSYM}.tgz" --directory $(dirname "$dSYM") $(basename "$dSYM")
                rm -rf "$dSYM";
            done
            for dSYM in $web_dsyms; do
                # Remove the web dsyms since they are so heavy.
                echo "Removing $dSYM"
                rm -rf "$dSYM"
            done

        elif [[ $isLinux -eq 1 ]]; then
            # Adjust RUNPATHS of libraries in install directory

            # Copy system ICU libs into the package.
            for iculib in icui18n icuuc icudata ; do
                cp --preserve=mode -P /lib64/lib${iculib}.so.* lib/
            done

            set +e
            find . -name libQt?Core.so.$QTVERSION | xargs patchelf --set-rpath "\$ORIGIN"
            if [ $? -ne 0 ]; then
                echo "**** Failed to set qtbase/core rpath ****"
                exit 1
            fi

            find . -name libQt?WebEngineCore.so.$QTVERSION | xargs patchelf --set-rpath "\$ORIGIN"
            if [ $? -ne 0 ]; then
                echo "**** Failed to set qtwebengine/core rpath ****"
                exit 1
            fi
            set -e
        fi

        # Compress folders for Maya devkit
        tar -czf qt_$QTVERSION-include.tar.gz --directory=include/ . && \
        tar -czf qt_$QTVERSION-cmake.tar.gz --directory=lib/cmake/ . && \
        tar -czf qt_$QTVERSION-mkspecs.tar.gz --directory=mkspecs/ .
        COMPRESS_RETURNCODE=$?
        if [ $COMPRESS_RETURNCODE -eq 0 ]; then
            echo "==== Tar files created ===="
        fi
    fi
fi

exitIfFailed $CONFIGURE_RETURNCODE "configure build"
exitIfFailed $BUILD_RETURNCODE  "build"
exitIfFailed $INSTALL_RETURNCODE "create install"
exitIfFailed $COMPRESS_RETURNCODE "create tar files"

echo -n "End timestamp: "; date
echo "==== Success ===="
