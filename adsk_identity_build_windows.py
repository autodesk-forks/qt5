import os
import shutil
import time
import subprocess
import sys
import getopt

# ----------------------------------------------------------------------------
# Prepare the workspace, depedency library and tools
# ----------------------------------------------------------------------------
PLATFORM = os.environ['TARGET_PLATFORM']
EXTERNAL_DIR = os.environ['EXTERNAL_DIR']
OPENSSL_DIR = os.path.join(EXTERNAL_DIR, 'openssl/1.1.1')
ICU_DIR = os.path.join(EXTERNAL_DIR, 'icu')
JOM = os.path.join(EXTERNAL_DIR, 'Jom/1.1.2/jom.exe')
TARGET_DIR = 'dist/Qt/5.12.2'
BUILD_DIR = 'build'
sys.path.append(os.path.join(os.getcwd(), 'qtbase', 'bin'))
sys.path.append(os.path.join(os.getcwd(), 'gnuwin32', 'bin'))

# ----------------------------------------------------------------------------
# here we go!
# ----------------------------------------------------------------------------
START_TIME = time.time()

# ----------------------------------------------------------------------------
# we now set some real pathes to be used later
# ----------------------------------------------------------------------------
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))
PREFIX_PATH = os.path.realpath(os.path.join(SCRIPT_PATH, TARGET_DIR))

BUILD_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, BUILD_DIR))

OPENSSL_INCLUDE_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, OPENSSL_DIR, 'include'))
OPENSSL_LIB_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, OPENSSL_DIR, 'binary', 'win_vc14', PLATFORM, 'lib'))
	
ICU_INCLUDE_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, ICU_DIR, 'icu_win_release_v140.64.2.0', 'include'))
ICU_LIB_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, ICU_DIR, 'icu_win_release_v140.64.2.0', 'binary', 'win_vc14', PLATFORM, 'lib'))

BUILD_ENV = os.environ.copy()
# BUILD_ENV['QMAKE_CXXFLAGS'] = '-DWIN_VER=0x0601 -D_WIN32_WINNT=0x0601'

if not os.path.exists(BUILD_PATH):
    os.mkdir(BUILD_PATH)
os.chdir(BUILD_PATH)

CONFIGURE = os.path.relpath(os.path.join(SCRIPT_PATH, 'configure'))

# -------------------------------------------------------------------------
# copy our fancy multi-thread build tool into our build_path
# -------------------------------------------------------------------------
shutil.copy(JOM,
            os.path.join(BUILD_PATH, 'jom.exe'))

# -----------------------------------------------------------------------------
# Setting up the Build Configuration
# -----------------------------------------------------------------------------
subprocess.check_call(
    CONFIGURE +
    ' -openssl ' 
    ' -I \"' + OPENSSL_INCLUDE_PATH + '\" '
    ' -icu ' 
    ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
    ' -platform win32-msvc ' 
    ' -opengl dynamic ' 
    ' -plugin-sql-sqlite -qtlibinfix _Ad_5_12 -qt-libjpeg -qt-zlib '
    ' -debug-and-release -force-debug-info -developer-build -nomake examples -nomake tests '
    ' -prefix \"' + PREFIX_PATH + '\" '
    ' -opensource -confirm-license ',
    env=BUILD_ENV, shell=True)


# -----------------------------------------------------------------------------
# Start the build
# -----------------------------------------------------------------------------
subprocess.check_call('jom', env=BUILD_ENV, shell=True)
subprocess.check_call('jom install', env=BUILD_ENV, shell=True)


# -----------------------------------------------------------------------------
# cleaning up unnecessary release pdbs...
# -----------------------------------------------------------------------------
for f in os.listdir(os.path.join(PREFIX_PATH, 'bin')):
    if f.endswith('.pdb') and not f.endswith('d.pdb'):
        if os.path.exists( os.path.join(PREFIX_PATH, 'bin', f[:-4] + '.exe' ) ):
            print ('deleting unwanted ' + f)
            os.remove(os.path.join(PREFIX_PATH, 'bin', f))
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# we have to provide a relative prefix qt.conf file to allow qmake to work from
# a different location.
# -----------------------------------------------------------------------------
with open( os.path.join(PREFIX_PATH, 'bin', 'qt.conf'), 'w' ) as qt_conf_file: 
    qt_conf_file.write('[Paths]\n')
    qt_conf_file.write('Prefix=..\n')
    qt_conf_file.close()


END_TIME = time.time()

TOOK_SECONDS = END_TIME - START_TIME
print ('\n\nBuilding Qt5 took %02d:%02d\n' % (TOOK_SECONDS / 60, TOOK_SECONDS % 60))
