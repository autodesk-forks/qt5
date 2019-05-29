if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
	exit 1
fi

if [[ -z "${QTVERSION}" ]]; then
	echo "QTVERSION is undefined.  Example: export QTVERSION=5.12.2"
	exit 1
else
	echo "QTVERSION=${QTVERSION}"
fi

export WORKDIR=$1
export SRCDIR=$WORKDIR/src
export INSTALLDIR=$WORKDIR/install/qt_$QTVERSION
export BUILDDIR=$WORKDIR/build

export NUMBER_OF_PROCESSORS=`sysctl -n hw.ncpu`
echo "make -j$NUMBER_OF_PROCESSORS"
$SRCDIR/configure --prefix=$INSTALLDIR -debug-and-release -no-strip -force-debug-info -opensource -plugin-sql-sqlite -silent -opengl desktop -no-framework -no-warnings-are-errors -confirm-license -nomake examples -nomake tests
if [ $? -eq 0 ]; then
    make -j$NUMBER_OF_PROCESSORS
        if [ $? -eq 0 ]; then
                make install
                if [ $? -eq 0 ]; then
                        cd $INSTALLDIR

                        for x in $(ls ./**/*.dylib); do
                                if ! [ -L $x ]; then
                                        echo Generating debug symbols for $x
                                        dsymutil $x;
                                        tar -czf $x.dSYM.tgz --directory $(dirname $x) $(basename $x).dSYM ;
                                        rm -rf $x.dSYM;
                                fi
                        done

                        for x in $(ls ./**/**/*.dylib); do
                                if ! [ -L $x ]; then
                                        echo Generating debug symbols for $x
                                        dsymutil $x;
                                        tar -czf $x.dSYM.tgz --directory $(dirname $x) $(basename $x).dSYM ;
                                        rm -rf $x.dSYM;
                                fi
                        done

                        # And remove the webkit webengine debug symbols because they are incredibly heavy
                        # more than half of the artifact
                        rm -vf lib/libQt5Web*.dSYM.tgz

                        tar -czf qt_$QTVERSION-include.tar.gz --directory=include/ . && \
                        tar -czf qt_$QTVERSION-cmake.tar.gz --directory=lib/cmake/ . && \
                        tar -czf qt_$QTVERSION-mkspecs.tar.gz --directory=mkspecs/ . && \
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