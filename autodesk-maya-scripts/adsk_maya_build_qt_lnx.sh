#!/usr/bin/env bash

set -e # Terminate with failure if any command returns nonzero
set -u # Terminate with failure any time an undefined variable is expanded

SCRIPT_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" >/dev/null 2>&1 && pwd)"

echo -n "Start timestamp: "; date
# Parameter 1 - Absolute path to workspace directory
if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
    exit 1
fi

# Location of the workspace directory (root of the folder structure)
export WORKSPACE_DIR=$1

set +u
# Environment Variable - QTVERSION - Version of Qt to build
if [[ -z "${QTVERSION}" ]]; then
    echo "QTVERSION is undefined. Example: export QTVERSION=5.15.2"
    exit 1
else
    echo "QTVERSION=${QTVERSION}"
fi
set -u

# Location where the final build will be located, as defined by the -prefix option
export INSTALL_DIR=$WORKSPACE_DIR/install/qt_$QTVERSION

# Location of the source code directory (top of git tree - qt5.git)
export SOURCE_DIR=$(readlink -f "$SCRIPT_DIR/..")

#if [[ ! "${QTVERSION}" =~ [:digit:]\.[:digit:]+\.[:digit:]* ]]; then
if [[ ! "${QTVERSION}" =~ [0-9]\.[0-9]+\.[0-9]* ]]; then
    echo "QTVERSION is not a version number!"
    echo "That value will only be used for the install prefix."
    echo -n "Figuring it out from the codebase... "
    QTVERSION=$(python $SCRIPT_DIR/fetch-qt-version.py ${SOURCE_DIR})
    echo "Qt version: $QTVERSION"
fi

# Location of openssl include directory (optional) within the external dependencies directory
export OPENSSL_DIR=$WORKSPACE_DIR/external_dependencies/openssl/1.1.1g/RelWithDebInfo

# Print GCC, Python and patchelf versions
set +e
gcc --version | head -1
gcc --version >/dev/null 2>&1
compiler_ret=$?
python --version
python_ret=$?
patchelf --version
patchelf_ret=$?
set -e

if [ $compiler_ret -ne 0 ]; then
    echo "Compiler (xcode, gcc, msvc) not present. Aborting."
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

# To prevent an out-of-memory error when building Chromium, we do not use all available processors to build Qt.
export NUMBER_OF_PROCESSORS_TOTAL=`cat /proc/cpuinfo | grep processor | wc -l`
export NUMBER_OF_PROCESSORS=$((NUMBER_OF_PROCESSORS_TOTAL * 1/2))

# Define the modules to skip (because they are under commercial license)
export MODULES_TO_SKIP="-skip qtnetworkauth -skip qtpurchasing -skip qtquickcontrols -skip qtquick3d -skip qtlottie -skip qtcharts -skip qtdatavis3d -skip qtvirtualkeyboard -skip qtscript -skip qtwayland -skip qtwebglplugin"

# Configure the build
# Configure options: https://wiki.qt.io/Qt_5.15_Tools_and_Versions
# Note: Flag -qt-xcb is removed in Qt 5.15
set +e # Continue if commands fail, as we have explicit failure handling
$SOURCE_DIR/configure -opensource -confirm-license -verbose -prefix $INSTALL_DIR -release -nomake tests -nomake examples -no-libudev -no-use-gold-linker -force-debug-info -separate-debug-info -no-sql-mysql -plugin-sql-psql -plugin-sql-sqlite -qt-libjpeg -qt-libpng -xcb -bundled-xcb-xinput -sysconfdir /etc/xdg -qt-pcre -qt-harfbuzz -R . -icu -opengl desktop -qt-qt3d-assimp $MODULES_TO_SKIP -openssl -I $OPENSSL_DIR/include -L $OPENSSL_DIR/lib
CONFIGURE_RETURNCODE=$?
echo -n "End Configure timestamp: "; date
if [ $CONFIGURE_RETURNCODE -eq 0 ]; then
    # Build
    make -j $NUMBER_OF_PROCESSORS
    BUILD_RETURNCODE=$?
    echo -n "End Build timestamp: "; date
    if [ $BUILD_RETURNCODE -eq 0 ]; then
        make install
        INSTALL_RETURNCODE=$?
        echo -n "End make install timestamp: "; date
        if [ $INSTALL_RETURNCODE -eq 0 ]; then
            # Adjust RUNPATHS of libraries in install directory
            set -e
            cd $INSTALL_DIR
            set +e

            # Copy system ICU libs into the package.
            for iculib in icui18n icuuc icudata ; do
                cp --preserve=mode -P /lib64/lib${iculib}.so.* lib/
            done

            set +e
            find . -name libQt?Core.so | xargs patchelf --set-rpath "\$ORIGIN"
            if [ $? -ne 0 ]; then
                echo "**** Failed to set qtbase/core rpath ****"
                exit 1
            fi

            find . -name libQt?WebEngineCore.so | xargs patchelf --set-rpath "\$ORIGIN"
            if [ $? -ne 0 ]; then
                echo "**** Failed to set qtwebengine/core rpath ****"
                exit 1
            fi
            set -e

            # Compress folders for Maya devkit
            tar -czf qt_$QTVERSION-include.tar.gz --directory=include/ . && \
            tar -czvf qt_$QTVERSION-mkspecs.tar.gz --directory=mkspecs/ . && \
            tar -czvf qt_$QTVERSION-cmake.tar.gz --directory=lib/cmake/ . && \
            echo "==== Success ====" || echo "**** Failed to create tar files ****"
        else
            echo "**** Failed to create install ****"
            exit 1
        fi
    else
        echo "**** Failed to build ****"
        exit 1
    fi
else
    echo "**** Failed to configure build ****"
    exit 1
fi

echo -n "End timestamp: "; date
