import os
import shutil
import time
import subprocess
import sys
import getopt

# ----------------------------------------------------------------------------
# Prepare the workspace, depedency library and tools
# ----------------------------------------------------------------------------
PLATFORM = 'x64'
TARGET_DIR = 'dist/Qt/5.12.7'
BUILD_DIR = 'build'
sys.path.append(os.path.join(os.getcwd(), 'qtbase', 'bin'))
sys.path.append(os.path.join(os.getcwd(), 'gnuwin32', 'bin'))

# ----------------------------------------------------------------------------
# Initialise the all submodules repositories
# ----------------------------------------------------------------------------
subprocess.check_call('perl init-repository --force', shell=True)

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

BUILD_ENV = os.environ.copy()
# BUILD_ENV['QMAKE_CXXFLAGS'] = '-DWIN_VER=0x0601 -D_WIN32_WINNT=0x0601'

if not os.path.exists(BUILD_PATH):
    os.mkdir(BUILD_PATH)
os.chdir(BUILD_PATH)

CONFIGURE = os.path.relpath(os.path.join(SCRIPT_PATH, 'configure'))

# -----------------------------------------------------------------------------
# Setting up the Build Configuration
# -----------------------------------------------------------------------------
subprocess.check_call(
    CONFIGURE +
    ' -silent '
    ' -opengl desktop ' 
    ' -plugin-sql-sqlite -qt-libjpeg -qt-zlib '
    ' -debug-and-release -no-strip  -force-debug-info -developer-build '
    ' -framework -nomake examples -nomake tests '
    ' -no-warnings-are-errors '
    ' -prefix \"' + PREFIX_PATH + '\" '
    ' -separate-debug-info '
    ' -opensource -confirm-license ',
    env=BUILD_ENV, shell=True)

# -----------------------------------------------------------------------------
# Start the build
# -----------------------------------------------------------------------------
subprocess.check_call('make -j4', env=BUILD_ENV, shell=True)
subprocess.check_call('make install', env=BUILD_ENV, shell=True)


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
