
import os
import shutil
import time
import subprocess
import sys
import getopt

OPENSSL_DIR = '../openssl/1.0.2j'
ICU_DIR = '../icu'

TARGET_DIR = '../qt5_dist'

BUILD_DIR_DEBUG = '../qt5_build_debug'
BUILD_DIR_RELEASE = '../qt5_build_release'
BUILD_DIR = '../qt5_build'

# ----------------------------------------------------------------------------
try:
    opts, args = getopt.getopt( sys.argv[1:],"dr",["debug","release"])
except getopt.GetoptError:
    print 'adsk_3dsmax_build.py [--debug|--release]'
    sys.exit(2)

MODE = ''
for opt, arg in opts:
    if opt == '-h':
        print 'adsk_3dsmax_build.py [--debug|--release]'
        sys.exit()
    elif opt in ("-d", "--debug"):
        if MODE == 'release':
            MODE = 'debug_and_release'
        else:
            MODE = 'debug'
    elif opt in ("-r", "--release"):
        if MODE == 'debug':
            MODE = 'debug_and_release'
        else:
            MODE = 'release'
# ----------------------------------------------------------------------------
if ( MODE == ''): 
    MODE = 'debug_and_release'

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

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
if MODE == 'debug' or MODE == 'debug_and_release':
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

    if not os.path.exists(BUILD_PATH_DEBUG):
        os.mkdir(BUILD_PATH_DEBUG)
    os.chdir(BUILD_PATH_DEBUG)

    CONFIGURE = os.path.relpath(os.path.join(SCRIPT_PATH, 'configure'))

    # -------------------------------------------------------------------------
    # copy our fancy multi-thread build tool into our build_paths
    # -------------------------------------------------------------------------
    shutil.copy(os.path.join(SCRIPT_PATH, 'jom.exe'),
                os.path.join(BUILD_PATH_DEBUG, 'jom.exe'))

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
        # ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
        #' -make tests'
        ' -debug ', env=BUILD_ENV, shell=True)

    subprocess.check_call('jom', env=BUILD_ENV, shell=True)
    subprocess.check_call('jom install', env=BUILD_ENV, shell=True)

    # -------------------------------------------------------------------------
    # we have to rename that file to keep it from getting overridden by the 
    # build if following...
    # -------------------------------------------------------------------------
    if os.path.exists(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe')):
        os.remove(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe'))

    os.rename(os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcess.exe'),
            os.path.join(PREFIX_PATH, 'bin', 'QtWebEngineProcessd.exe'))

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
if MODE == 'release' or MODE == 'debug_and_release':
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

    if not os.path.exists(BUILD_PATH_RELEASE):
        os.mkdir(BUILD_PATH_RELEASE)
    os.chdir(BUILD_PATH_RELEASE)

    CONFIGURE = os.path.relpath(os.path.join(SCRIPT_PATH, 'configure'))
    
    # -----------------------------------------------------------------------------
    # copy our fancy multi-thread build tool into our build_paths
    # -----------------------------------------------------------------------------
    shutil.copy(os.path.join(SCRIPT_PATH, 'jom.exe'),
                os.path.join(BUILD_PATH_RELEASE, 'jom.exe'))

    subprocess.check_call(
        CONFIGURE +
        ' -opensource -confirm-license '
        ' -nomake examples -no-compile-examples -no-cetest '
        ' -qt-zlib -qt-libpng '
        ' -opengl dynamic '
        ' -mp -prefix \"' + PREFIX_PATH + '\" '
        ' -openssl OPENSSL_LIBS_DEBUG="-llibeay32 -lssleay32" '
        ' OPENSSL_LIBS_RELEASE="-llibeay32 -lssleay32" '
        ' -I \"' + OPENSSL_INCLUDE_PATH + '\" -L \"' + OPENSSL_LIB_PATH + '\"'
        ' -no-icu ' # we just enable icu for the webkit module that we compile
                    # in a separate step
        # ' -icu ' +
        # ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
        ' -make tests'
        ' -release ', env=BUILD_ENV, shell=True)

    subprocess.check_call('jom', env=BUILD_ENV, shell=True)
    subprocess.check_call('jom install', env=BUILD_ENV, shell=True)

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# cleaning up unnecessary release pdbs...
# -----------------------------------------------------------------------------
for f in os.listdir(os.path.join(PREFIX_PATH, 'bin')):
    if f.endswith('.pdb') and not f.endswith('d.pdb'):
        print 'deleting unwanted ' + f + '\n'
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
print '\n\nBuilding Qt5 in %s took %02d:%02d\n' % (MODE, TOOK_SECONDS / 60, TOOK_SECONDS % 60)
