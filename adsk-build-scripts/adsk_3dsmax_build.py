
import os
import shutil
import time
import subprocess
import sys
import getopt

OPENSSL_DIR = 'deps/openssl'
#ICU_DIR = '../icu'

TARGET_DIR = 'dist/Qt/5.12.1'
BUILD_DIR = 'build'

# ----------------------------------------------------------------------------
try:
    opts, args = getopt.getopt(sys.argv[1:], "dr", ["debug", "release"])
except getopt.GetoptError:
    print('adsk_3dsmax_build.py [--debug|--release]')
    sys.exit(2)

MODE = ''
for opt, arg in opts:
    if opt == '-h':
        print('adsk_3dsmax_build.py [--debug|--release]')
        sys.exit()
    elif opt in ("-d", "--debug"):
        if MODE == 'release':
            MODE = 'debug-and-release'
        else:
            MODE = 'debug'
    elif opt in ("-r", "--release"):
        if MODE == 'debug':
            MODE = 'debug-and-release'
        else:
            MODE = 'release'
# ----------------------------------------------------------------------------
if (MODE == ''):
    MODE = 'debug-and-release'

# ----------------------------------------------------------------------------
# here we go!
# ----------------------------------------------------------------------------
START_TIME = time.time()
# ----------------------------------------------------------------------------
# we now set some real pathes to be used later
# ----------------------------------------------------------------------------
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))
ROOT_PATH = os.path.realpath(os.path.join(SCRIPT_PATH, '..'))
PREFIX_PATH = os.path.realpath(os.path.join(ROOT_PATH, TARGET_DIR))
BUILD_PATH = os.path.realpath(
    os.path.join(ROOT_PATH, BUILD_DIR))

print('\nSCRIPT_PATH: %s\nROOT_PATH:   %s\nPREFIX_PATH: %s\nBUILD_PATH:  %s\n' % (
    SCRIPT_PATH, ROOT_PATH, PREFIX_PATH, BUILD_PATH))

OPENSSL_INCLUDE_PATH = os.path.realpath(
    os.path.join(ROOT_PATH, OPENSSL_DIR, 'include'))
OPENSSL_LIB_PATH = os.path.realpath(
    os.path.join(ROOT_PATH, OPENSSL_DIR, 'lib'))
OPENSSL_LIB_PATH_DEBUG = os.path.realpath(
    os.path.join(ROOT_PATH, OPENSSL_DIR, 'lib', 'debug'))

# ICU_INCLUDE_PATH = os.path.realpath(
#    os.path.join(ROOT_PATH, ICU_DIR, 'include'))
# ICU_LIB_PATH = os.path.realpath(
#    os.path.join(ROOT_PATH, ICU_DIR, 'lib'))

BUILD_ENV = os.environ.copy()
BUILD_ENV['QMAKE_CXXFLAGS'] = '-DWIN_VER=0x0601 -D_WIN32_WINNT=0x0601'

if not os.path.exists(BUILD_PATH):
    os.mkdir(BUILD_PATH)
os.chdir(BUILD_PATH)

CONFIGURE = os.path.relpath(os.path.join(ROOT_PATH, 'configure.bat'))

# -------------------------------------------------------------------------
# copy our fancy multi-thread build tool into our build_path
# -------------------------------------------------------------------------
shutil.copy(os.path.join(ROOT_PATH, 'jom.exe'),
            os.path.join(BUILD_PATH, 'jom.exe'))
subprocess.check_output([os.path.join(BUILD_PATH, 'jom.exe'), '/VERSION'])

try:
    subprocess.check_output(
        CONFIGURE +
        ' -opensource -confirm-license '
        ' -nomake examples -no-compile-examples '
        ' -qt-zlib -qt-libpng '
        ' -opengl dynamic '
        ' -mp -prefix \"' + PREFIX_PATH + '\" '
        ' -ssl -openssl '
        ' OPENSSL_LIBS_DEBUG="-llibeay32 -lssleay32" ' +
        ' OPENSSL_LIBS_RELEASE="-llibeay32 -lssleay32" ' +
        ' OPENSSL_LIBDIR=\"' + OPENSSL_LIB_PATH_DEBUG + '\" ' +
        ' OPENSSL_INCDIR=\"' + OPENSSL_INCLUDE_PATH + '\\openssl\" ' +
        ' -I \"' + OPENSSL_INCLUDE_PATH + '\" -L \"' + OPENSSL_LIB_PATH_DEBUG + '\"' +
        # ' -no-icu ' +  # we just enable icu for the webkit module that we compile
        # in a separate step
        # ' -icu ' +
        # ' -I \"' + ICU_INCLUDE_PATH + '\" -L \"' + ICU_LIB_PATH + '\"'
        ' -make tests '
        ' -make tools '
        ' -force-debug-info '
        '-' + MODE,
        env=BUILD_ENV, shell=True)
except subprocess.CalledProcessError as exc:
    print('\n\n-----------------------------------------------------------------------------\n'
          'Configure failed: \n' + exc.output )
    raise

# subprocess.check_output('nmake', env=BUILD_ENV, shell=True)
# subprocess.check_output('nmake install', env=BUILD_ENV, shell=True)
try:
    subprocess.check_output('jom', env=BUILD_ENV, shell=True)
except subprocess.CalledProcessError as exc:
    print('\n\n-----------------------------------------------------------------------------\n'
          'jom build failed: \n' + exc.output + '\nretrying with nmake...' )
    subprocess.check_output('nmake', env=BUILD_ENV, shell=True)

try:
    subprocess.check_output('jom install', env=BUILD_ENV, shell=True)
except subprocess.CalledProcessError as exc:
    print('\n\n-----------------------------------------------------------------------------\n'
          'jom install failed: \n' + exc.output + '\nretrying with nmake...' )
    subprocess.check_output('nmake install', env=BUILD_ENV, shell=True)

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# cleaning up unnecessary release pdbs...
# -----------------------------------------------------------------------------
for f in os.listdir(os.path.join(PREFIX_PATH, 'bin')):
    if f.endswith('.pdb') and not f.endswith('d.pdb'):
        if os.path.exists(os.path.join(PREFIX_PATH, 'bin', f[:-4] + '.exe')):
            print('deleting unwanted ' + f)
            os.remove(os.path.join(PREFIX_PATH, 'bin', f))
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# we have to provide a relative prefix qt.conf file to allow qmake to work from
# a different location.
# -----------------------------------------------------------------------------
with open(os.path.join(PREFIX_PATH, 'bin', 'qt.conf'), 'w') as qt_conf_file:
    qt_conf_file.write('[Paths]\n')
    qt_conf_file.write('Prefix=..\n')
    qt_conf_file.close()


END_TIME = time.time()

TOOK_SECONDS = END_TIME - START_TIME
print('\n\nBuilding Qt5 in %s took %02d:%02d:%02d\n' % (
    MODE, TOOK_SECONDS / 3600, TOOK_SECONDS / 60, TOOK_SECONDS % 60))
