
import os
import shutil
import time
import subprocess

OPENSSL_DIR = '../openssl/1.0.2j'
ICU_DIR = '../icu'

TARGET_DIR = '../qt5_dist'

BUILD_DIR_DEBUG = '../qt5_build_debug'
BUILD_DIR_RELEASE = '../qt5_build_release'

# ----------------------------------------------------------------------------
# here we go!
# ----------------------------------------------------------------------------
START_TIME = time.time()
# ----------------------------------------------------------------------------
# we now set some real pathes to be used later
# ----------------------------------------------------------------------------
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))
PREFIX_PATH = os.path.realpath(os.path.join(SCRIPT_PATH, TARGET_DIR))

BUILD_PATH_DEBUG = os.path.realpath(
    os.path.join(SCRIPT_PATH, BUILD_DIR_DEBUG))
BUILD_PATH_RELEASE = os.path.realpath(
    os.path.join(SCRIPT_PATH, BUILD_DIR_RELEASE))

OPENSSL_INCLUDE_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, OPENSSL_DIR, 'include'))
OPENSSL_LIB_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, OPENSSL_DIR, 'lib'))
OPENSSL_LIB_PATH_DEBUG = os.path.realpath(
    os.path.join(SCRIPT_PATH, OPENSSL_DIR, 'debug', 'lib'))

ICU_INCLUDE_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, ICU_DIR, 'include'))
ICU_LIB_PATH = os.path.realpath(
    os.path.join(SCRIPT_PATH, ICU_DIR, 'lib'))

BUILD_ENV = os.environ.copy()
BUILD_ENV['QMAKE_CXXFLAGS'] = '-DWIN_VER=0x0601 -D_WIN32_WINNT=0x0601'

if not os.path.exists(BUILD_PATH_DEBUG):
    os.mkdir(BUILD_PATH_DEBUG)
os.chdir(BUILD_PATH_DEBUG)

# -----------------------------------------------------------------------------
# copy our fancy multi-thread build tool into our build_paths
# -----------------------------------------------------------------------------
shutil.copy(os.path.join(SCRIPT_PATH, 'jom.exe'),
            os.path.join(BUILD_PATH_DEBUG, 'jom.exe'))

CONFIGURE = os.path.relpath(os.path.join(SCRIPT_PATH, 'configure'))

subprocess.check_call(
    CONFIGURE +
    ' -opensource -confirm-license '
    ' -nomake examples -no-compile-examples -no-cetest '
    ' -qt-zlib -qt-libpng '
    ' -opengl dynamic '
    ' -mp -prefix \"' + PREFIX_PATH + '\" '
    ' -openssl '
    ' OPENSSL_LIBS_DEBUG="-llibeay32 -lssleay32" ' +
    ' OPENSSL_LIBS_RELEASE="-llibeay32 -lssleay32" ' +
    ' -I \"' + OPENSSL_INCLUDE_PATH + '\" -L \"' + OPENSSL_LIB_PATH_DEBUG + '\"' +
    ' -no-icu ' +  # we just enable icu for the webkit module that we compile
                   # in a separate step
    # ' -icu ' +
    ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
    ' -debug ', env=BUILD_ENV, shell=True)

subprocess.check_call('jom', env=BUILD_ENV, shell=True)
subprocess.check_call('jom install', env=BUILD_ENV, shell=True)

# -----------------------------------------------------------------------------
# we have to rename that file to keep it from getting overridden by the release
# build following...
# -----------------------------------------------------------------------------
if os.path.exists(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe')):
    os.remove(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe'))

os.rename(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcess.exe'),
          os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe'))

# -----------------------------------------------------------------------------
# cleaning up unnecessary release pdbs...
# -----------------------------------------------------------------------------
for f in os.listdir(os.path.join(PREFIX_PATH, 'bin')):
    if f.endswith('.pdb') and not f.endswith('d.pdb'):
        print 'deleting unwanted ' + f + '\n'
        os.remove(os.path.join(PREFIX_PATH, 'bin', f))
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# DEBUG BUILD DONE - STARTING RELEASE BUILD !!!
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

if not os.path.exists(BUILD_PATH_RELEASE):
    os.mkdir(BUILD_PATH_RELEASE)

os.chdir(BUILD_PATH_RELEASE)
# -----------------------------------------------------------------------------
# copy our fancy multi-thread build tool into our build_paths
# -----------------------------------------------------------------------------
shutil.copy(os.path.join(SCRIPT_PATH, 'jom.exe'),
            os.path.join(BUILD_PATH_RELEASE, 'jom.exe'))

subprocess.check_call(
    CONFIGURE +
    ' -opensource -confirm-license ' +
    ' -nomake examples -no-compile-examples -no-cetest ' +
    ' -qt-zlib -qt-libpng ' +
    ' -opengl dynamic ' +
    ' -mp -prefix \"' + PREFIX_PATH + '\" ' +
    ' -openssl OPENSSL_LIBS_DEBUG="-llibeay32 -lssleay32" ' +
    ' OPENSSL_LIBS_RELEASE="-llibeay32 -lssleay32" ' +
    ' -I \"' + OPENSSL_INCLUDE_PATH + '\" -L \"' + OPENSSL_LIB_PATH + '\"' +
    ' -no-icu ' +  # we just enable icu for the webkit module that we compile
                   # in a separate step
    # ' -icu ' +
    ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
    ' -release ', env=BUILD_ENV, shell=True)

subprocess.check_call('jom', env=BUILD_ENV, shell=True)
subprocess.check_call('jom install', env=BUILD_ENV, shell=True)

# -----------------------------------------------------------------------------
# we have to provide a relative prefix qt.conf file to allow qmake to work from
# a different location.
# -----------------------------------------------------------------------------
with open( os.path.join(PREFIX_PATH, 'bin', 'qt.conf'), 'w' ) as qt_conf_file: 
    qt_conf_file.write('[Paths]\n')
    qt_conf_file.write('Prefix=..\n')
    qt_conf_file.close()


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# RELEASE BUILD DONE !!!
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

END_TIME = time.time()

TOOK_SECONDS = END_TIME - START_TIME
print '\n\nBuilding Qt5 took %02d:%02d\n' % (TOOK_SECONDS / 60, TOOK_SECONDS % 60)
