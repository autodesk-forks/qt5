# HOW TO BUILD QT 6 - Maya Build Branch

This branch is based on the official [v6.2.3](https://code.qt.io/cgit/qt/qt5.git/tag/?h=v6.2.3) tag. Instructions to compile a Maya compatible version are below.

For the original Qt 6 build instructions, see [HOW TO BUILD QT 6](README.md).

# Building Qt 6 for Maya <a name="top-header"></a>

This page explains how Qt 6 was built for Maya.

Before starting, make sure to read the documentation provided by the Qt Company. It lists required system dependencies, build tools and describes how to build Qt from source code for each platform.

Qt Documentation:
- Build Sources - https://doc.qt.io/qt-6/build-sources.html
- Building Qt 6 from Git - https://wiki.qt.io/Building_Qt_6_from_Git
- Linux Requirements - https://doc.qt.io/qt-6/linux-requirements.html
- Configure Options - https://wiki.qt.io/Qt_6.2_Tools_and_Versions

Build Scripts:<a name="build-scripts-links"></a>

The following instructions make use of build scripts to configure build options, compile Qt, and package it for Maya. These scripts are available in this repository in the directory `autodesk-maya-scripts`.

To provide maximum flexibility to end-users, Maya only relies on LGPL-licensed Qt components. We do not build or use:
- `qtnetworkauth`
- `qtpurchasing`
- `qtquick3d`
- `qtlottie`
- `qtcharts`
- `qtdatavis3d`
- `qtvirtualkeyboard`
- `qtwayland`
- `qtwebglplugin`


> **Minimum OpenSSL Version**
Since Qt 5.15, Qt requires a minimum OpenSSL version of 1.1.1 (if the `--openssl` option is enabled). OpenSSL is used by the Qt Network submodule. This option is only available for Windows and Linux, since Mac uses Apple's Secure Transport API.

> **Xcb Libraries**
Since XCB libraries are no longer included with Qt on Linux, starting with version 5.15 of Qt, the -qt-xcb build configuration option is no longer supported. Before building Qt on Linux, make sure that XCB libraries are installed on your system, using available package/library managers.

#### Requirements / Setup <a name="build-requirements-header"></a>

To build Qt, you'll need the following tools:
- Git (>= 1.6.x)
- Perl (>= 5.14)
- Python (>= 2.7.x)
- Supported C++ Compiler

| Platform  | Version       | C++ Compiler                       |
| --------- | ---------     | ------------                       |
| Windows   | Windows 10    | Visual Studio 2019                 |
| Mac       | OSX 10.14.1   | Xcode 12 (11 SDK)                  |
| Linux     | CentOS 8.6    | GCC 11.2.1 [gcc-toolset-11 11.1]   |


**Directory Structure** <a name="directory-structure"></a>

For the provided build scripts to work, you'll need to use the following directory structure, where `workspace_root` refers to the top-level directory:
- `workspace_root/`: contains all folders related to the build
    - `external_dependencies/`: contains the dependencies required to build Qt
        - `openssl`: contains the OpenSSL 1.1.1 artifact (on Windows and Linux), including the header files
    - `install/`: contains the Qt 6 build once complete
    - `src/`: contains the Qt 6 source code from Autodesk public fork (top of git tree - the `qt5.git` will be cloned into this directory)
        - `autodesk-maya-scripts/`: contains the build and package scripts for each platform (Windows, Mac and Linux)

**Qt 6 Source Code**

Once the directory structure is created, clone the Qt 6 source code in the `src/` folder. For convenience, a public fork with all the necessary patches is available at https://github.com/autodesk-forks/qt5/tree/adsk-contrib/maya/6.2.3/.

```sh
# Go to the workspace_root directory
cd /path/to/workspace_root

# Create the src/ folder that will contain the Qt 6 source code (top of git tree)
mkdir src

# Clone Autodesk's qt5 public fork (top of git tree) into the src/ directory
git clone https://github.com/autodesk-forks/qt5.git src

# Checkout the branch that was used to build Qt 6 for Maya
cd src
git checkout adsk-contrib/maya/6.2.3
```

Once the cloning process is complete, execute the following commands in a terminal to initialize the repository (in the `src/` directory):
```sh
# Clean each submodule
git submodule foreach --recursive && git clean -dfx

# Initialize each submodule
perl ./init-repository --force --module-subset=default
```

> Note: In addition to the above command (using perl), it is also possible to use git command `git submodule update --init --recursive` to update submodules. The approach using perl is recommended by Qt. Note that you may need to execute this command several times for initialization to complete properly.

#### Build Steps <a name="build-steps-header"></a>

After completing the setup steps, use provided scripts to build Qt.

Overall, the build scripts perform the following steps:
1. Define the locations of tools and external dependencies using variables
2. Initialize the compiler
3. Configure the build options
4. Compile
5. Change RUNPATHS of resulting libraries (for Linux and Mac)

Before using provided scripts, please review and adjust them as needed.

> The commands used to invoke scripts send all output to a log file to ease debugging. It is normal not to see any output in the terminal until scripts complete.

#### Windows <a name="build-steps-windows-header"></a>

External Dependencies:
- OpenSSL 1.1.1 (RelWithDebInfo) with header files

To run the build script on Windows, execute the following commands from the command-line:

```batch
REM Set the path to the root folder of the workspace
SET WORKSPACE_ROOT_PATH=LETTER:\\path\\to\\workspace_root

REM Set the Qt version to build
SET QTVERSION=6.2.3

REM Define the log file name
SET LOGFILE_NAME=qt_6_build_log

REM Launch the build script from the src/ directory
cd /D "%WORKSPACE_ROOT_PATH%\\src"
autodesk-maya-scripts\\adsk_maya_build_qt_win.bat "%WORKSPACE_ROOT_PATH%" > "%WORKSPACE_ROOT_PATH%\\%LOGFILE_NAME%.txt" 2>&1
```

#### Mac <a name="build-steps-mac-header"></a>

To run the build script on Mac, execute the following commands from the terminal:

```sh
# Set the path to the root folder of the workspace
export WORKSPACE_ROOT_PATH=/path/to/workspace_root

# Set the Qt version to build
export QTVERSION=6.2.3

# Generate a unique name for the log file with the datetime at the end
export LOGFILE_NAME=qt_6_build_log_`date +%Y-%m-%d-%H%M`

# Launch the build script from the src/ directory
# Note: Nothing will be displayed in the console, as the output is redirected to the log file.
cd "$WORKSPACE_ROOT_PATH/src"
bash ./autodesk-maya-scripts/adsk_maya_build_qt_osx.sh $WORKSPACE_ROOT_PATH &>$WORKSPACE_ROOT_PATH/$LOGFILE_NAME.txt
```

#### Linux <a name="build-steps-linux-header"></a>

To build Qt 6 on Linux, you must ensure that the following build dependencies are installed on your system before running the build scripts (see `install_qt_6_build_dependencies_linux.sh`). Also, on top of the tools listed in [Requirements / Setup](#build-requirements-header) and the Qt documentation, the `patchelf` utility is needed to adjust the RUNPATHs of the libraries after the build is completed.

External Dependencies:
- OpenSSL 1.1.1 (RelWithDebInfo) with header files

To run the build script on Linux, execute the following commands from the terminal:

```sh
# Set the path to the root folder of the workspace
export WORKSPACE_ROOT_PATH=/path/to/workspace_root

# Set the Qt version to build
export QTVERSION=6.2.3

# Generate a unique name for the log file with the date-time at the end
export LOGFILE_NAME=qt_6_build_log_`date +%Y-%m-%d-%H%M`

# Enable the GCC C++ compiler and Launch the build script from the src/ directory
# Note: Nothing will be displayed in the console, as the output is redirected to the log file.
cd "$WORKSPACE_ROOT_PATH/src"
scl enable devtoolset-9 'bash ./autodesk-maya-scripts/adsk_maya_build_qt_lnx.sh $WORKSPACE_ROOT_PATH &>$WORKSPACE_ROOT_PATH/$LOGFILE_NAME.txt'
```

[[Back to Top]](#top-header)
