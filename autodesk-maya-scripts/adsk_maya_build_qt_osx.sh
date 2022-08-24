# Parameter 1 - Absolute path to workspace directory
if [ $# -eq 0 ]; then
    echo "Need to pass workspace directory to the script"
    exit 1
fi

# Environment Variable - QTVERSION - Version of Qt to build
if [[ -z "${QTVERSION}" ]]; then
    echo "QTVERSION is undefined. Example: export QTVERSION=5.15.2"
    exit 1
else
    echo "QTVERSION=${QTVERSION}"
fi

# Location of the workspace directory (root of the folder structure)
export WORKSPACE_DIR=$1

# Location of the source code directory (top of git tree - qt5.git)
export SOURCE_DIR=$WORKSPACE_DIR/src

# REM Location where the final build will be located, as defined by the -prefix option
export INSTALL_DIR=$WORKSPACE_DIR/install/qt_$QTVERSION
INSTALL_DIR_x86=$WORKSPACE_DIR/install_x86
BUILD_DIR_x86=$WORKSPACE_DIR/build_x86
BUILD_DIR_ARM=$WORKSPACE_DIR/build_ARM

# Get the number of processors available to build Qt
export NUMBER_OF_PROCESSORS=`sysctl -n hw.ncpu`
echo "make -j$NUMBER_OF_PROCESSORS"

# Define the modules to skip (because they are under commercial license)
export MODULES_TO_SKIP="-skip qtnetworkauth -skip qtpurchasing -skip qtquickcontrols -skip qtquick3d -skip qtlottie -skip qtcharts -skip qtdatavis3d -skip qtvirtualkeyboard -skip qtscript -skip qtwayland -skip qtwebglplugin"

function exitIfFailed
{

  # $1 Last operation string
  
  if [ $? -ne 0 ]; then
    echo "***** Failed to ${1} *****"
    exit 1
  fi
  return 0
}

function buildQt
{
  # $1 architecture
  # $2 minimal version target
  # $3 prefix
  # $4 shadow location
  mkdir $4
  cd $4

  # Configure the build
  # Configure options: https://wiki.qt.io/Qt_5.15_Tools_and_Versions
  export FORCED_ARCH=$1
  $SOURCE_DIR/configure -opensource -confirm-license -verbose -prefix $3 QMAKE_APPLE_DEVICE_ARCHS=$1 -device-option QMAKE_MACOSX_DEPLOYMENT_TARGET=$2 -debug-and-release -force-debug-info -nomake tests -nomake examples -plugin-sql-sqlite -silent -no-strip -no-framework -opengl desktop -no-warnings-are-errors $MODULES_TO_SKIP

  exitIfFailed "configure ${1}"

  # Build
  make -j$NUMBER_OF_PROCESSORS
  exitIfFailed "build ${1}"

  # Populate install
  make install
  exitIfFailed "create install ${1}"
  
}

# Build for Intel
buildQt x86_64 "10.15" $INSTALL_DIR_x86 $BUILD_DIR_x86
exitIfFailed "Intel build"

# Build for Arm
buildQt arm64 "11" $INSTALL_DIR $BUILD_DIR_ARM
exitIfFailed "arm build"

# Create a UB Install using Lipo
echo "Lipo"
cd ${INSTALL_DIR}
for f in $( find . );
do
  if [[ -f "$f" && $f != *.sh && $f != *.py && $f != *.pl ]] && [[ -x "$f" || $f == *.a ]] && ! [ -L $f ]; then
    lipo "${INSTALL_DIR}/${f}" -verify_arch x86_64
    if [ $? -eq 0 ]; then
        echo "${INSTALL_DIR}/${f} already supports x86_64"
    else
      # check if thisfile is a arm file
      lipo "${INSTALL_DIR}/${f}" -verify_arch arm64
      if [ $? -eq 0 ]; then
        echo "combine ${INSTALL_DIR}/${f} and ${INSTALL_DIR_x86}/${f}"
        #check if the same  file exist in x86
        lipo "${INSTALL_DIR_x86}/${f}" -verify_arch x86_64
        
        exitIfFailed "find x86 version of ${f}"
        if [ $? -eq 0 ]; then
          lipo -create -output "${INSTALL_DIR}/${f}" "${INSTALL_DIR}/${f}" "${INSTALL_DIR_x86}/${f}"
      
          exitIfFailed "combine ${INSTALL_DIR}/${f} and ${INSTALL_DIR_x86}/${f}"
        else
          echo "* Failed to find x86 version of ${f}"
        fi
      fi
    fi
  fi
done


# Generate and compress debug symbols in install directory
# Skip webkit webengine debug symbols because they are incredibly heavy,
echo "tar dSYM"
cd $INSTALL_DIR
            
for x in $(ls ./**/*.dylib); do
   if ! [ -L $x ]; then
     if [[ $x != **/libQt5Web*.dylib ]]; then
       echo Generating debug symbols for $x
       dsymutil $x;
       exitIfFailed "dsymutil $x"
       if [ -d $x.dSYM ]; then
         # echo "recreating $x.dSYM.tgz"
         if [ -f $x.dSYM.tgz ]; then
           rm $x.dSYM.tgz
         fi
         tar -czf $x.dSYM.tgz --directory $(dirname $x) $(basename $x).dSYM ;
         rm -rf $x.dSYM;
       fi
     fi
   fi
done

for x in $(ls ./**/**/*.dylib); do
    if ! [ -L $x ]; then
     if [[ $x != **/libQt5Web*.dylib ]]; then
        echo Generating debug symbols for $x
        dsymutil $x;
        exitIfFailed "dsymutil $x"

        if [ -d $x.dSYM ]; then
          # echo "recreating $x.dSYM.tgz"
          if [ -f $x.dSYM.tgz ]; then
            rm $x.dSYM.tgz
          fi
          tar -czf $x.dSYM.tgz --directory $(dirname $x) $(basename $x).dSYM ;
          rm -rf $x.dSYM;
        fi
      fi
    fi
done


# Adjust RUNPATHs
find . -name libQt?Core.$QTVERSION.dylib | xargs install_name_tool -rpath @executable_path/../Frameworks @loader_path/../MacOS

exitIfFailed    echo "set qtbase/core rpath"

# Compress folders for Maya devkit
tar -czf qt_$QTVERSION-include.tar.gz --directory=include/ . && \
tar -czf qt_$QTVERSION-cmake.tar.gz --directory=lib/cmake/ . && \
tar -czf qt_$QTVERSION-mkspecs.tar.gz --directory=mkspecs/ . && \
echo "==== Success ====" || echo "**** Failed to create tar files ****"
