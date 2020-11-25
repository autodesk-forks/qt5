if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
    exit 1
fi

if [[ -z "${QTVERSION}" ]]; then
    echo "QTVERSION is undefined.  Example: export QTVERSION=5.15.2"
    exit 1
else
    echo "QTVERSION=${QTVERSION}"
fi

export WORKDIR=$1
export SRCDIR=$WORKDIR/src
export INSTALLDIR=$WORKDIR/install/qt_$QTVERSION
export BUILDDIR=$WORKDIR/build
export ARTIFACTORYDIR=$WORKDIR/artifactory
export OPENSSLDIR=$ARTIFACTORYDIR/openssl/1.1.1g/RelWithDebInfo

gcc --version
python --version
patchelf --version

# We use a fraction of the total number of processors available since building chromium takes too much memory when using all available processors
export NUMBER_OF_PROCESSORS_TOTAL=`cat /proc/cpuinfo | grep processor | wc -l`
export NUMBER_OF_PROCESSORS=$((NUMBER_OF_PROCESSORS_TOTAL * 1/2))

# 60588e1a5dd9b10803e078c741271cbe5713a51b - for qt 5.15, -qt-xcb is removed.
# Options that are used in https://wiki.qt.io/Qt_5.15_Tools_and_Versions:
# -opensource -confirm-license -verbose -prefix /home/qt/work/install -release -nomake tests -nomake examples -no-libudev -no-use-gold-linker -force-debug-info -separate-debug-info -no-sql-mysql -plugin-sql-psql -plugin-sql-sqlite -qt-libjpeg -qt-libpng -xcb -bundled-xcb-xinput -sysconfdir /etc/xdg -qt-pcre -qt-harfbuzz -R . -openssl -I {{.Env.OPENSSL_HOME}}/include -L {{.Env.OPENSSL_HOME}}/lib QMAKE_LFLAGS_APP+=-s
$SRCDIR/configure -opensource -confirm-license -verbose -prefix $INSTALLDIR -release -nomake tests -nomake examples -no-libudev -no-use-gold-linker -force-debug-info -separate-debug-info -no-sql-mysql -plugin-sql-psql -plugin-sql-sqlite -qt-libjpeg -qt-libpng -xcb -bundled-xcb-xinput -sysconfdir /etc/xdg -qt-pcre -qt-harfbuzz -R . -icu -opengl desktop -skip qtnetworkauth -skip qtpurchasing -openssl -I $OPENSSLDIR/include -L $OPENSSLDIR/lib
if [ $? -eq 0 ]; then
    make -j $NUMBER_OF_PROCESSORS
        if [ $? -eq 0 ]; then
                make install
                if [ $? -eq 0 ]; then
                        echo changing to $INSTALLDIR directory
                        cd $INSTALLDIR
                        echo Current directory is $(pwd)

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
