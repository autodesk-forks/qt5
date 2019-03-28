if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
        exit 1
fi

if [[ -z "${QTVERSION}" ]]; then
	echo "QTVERSION is undefined.  Example: export QTVERSION=qt_5.12.2"
	exit 1
else
	echo "QTVERSION=${QTVERSION}"
fi

export WORKDIR=$1
export SRCDIR=$WORKDIR/src
export INSTALLDIR=$WORKDIR/install/$QTVERSION
export BUILDDIR=$WORKDIR/build

gcc --version
python --version
export NUMBER_OF_PROCESSORS=`cat /proc/cpuinfo | grep processor | wc -l`
$SRCDIR/configure --prefix=$INSTALLDIR -no-strip -force-debug-info -opensource -plugin-sql-sqlite -openssl -verbose -no-icu -separate-debug-info -opengl desktop -qt-xcb -no-warnings-are-errors -no-libudev -no-egl -nomake examples -nomake tests -confirm-license
if [ $? -eq 0 ]; then
    make -j $NUMBER_OF_PROCESSORS
        if [ $? -eq 0 ]; then
                make install
                if [ $? -eq 0 ]; then
                        echo changing to $INSTALLDIR directory
                        cd $INSTALLDIR
                        echo Current directory is $(pwd)
                        tar -czf $QTVERSION-include.tar.gz --directory=include/ . && \
                        tar -czvf $QTVERSION-mkspecs.tar.gz --directory=mkspecs/ . && \
                        tar -czvf $QTVERSION-cmake.tar.gz --directory=lib/cmake/ . && \
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