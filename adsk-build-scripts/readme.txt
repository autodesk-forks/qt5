##########################################
#@file   readme.txt
#@brief  QtBuildScript readme
#@team   FARA/CM (Consistant Material scrum team)
#@author Huimin Wen(Jess)
#@date   5/1/2022
##########################################

Brief 
    BuildQtOnWin.bat  : The batch script to build Qt on Windows platform
    BuildQtOnMacOS.sh : The build script to build Qt on macOS platform
    BuildQtOnLinux.sh : The build script to build Qt on Linux platform
    3rdParty directory: Contains some files need to be copied to destination directory
    readme.txt        : It's me ^_^

Disk space (*****Attention*****)
    Every building will need 150~200G disk space, so assure the disk space is enough before trigger a building.

How to build Qt on macOS?
    1.Download and unzip the 3rd parties openssl, postgresql and LLVM from the artifactory repo (Future plan).
    2.Set the corresponding environment variables.
      export OPENSSL_ROOT_DIR=/usr/local/Cellar/openssl@1.1/1.1.1m.universal
      export PostgreSQL_ROOT=/usr/local/Cellar/postgresql@11/11.14_1
      export LLVM_INSTALL_DIR=/Volumes/DATA/Qt6/CommonTools/libclang
    3.Install the CMake 3.19.8 and we will use this CMake to buid Qt.
    4.Run the build script BuildQtOnMacOS.sh under the folder adsk-build-scripts.

Reset all the configurations
    Run the following commands under the qt5 folder to reset all the configurations.
    --------------------------------------------------
    git clean -xfd
    git submodule foreach --recursive git clean -xfd
    git reset --hard
    git submodule foreach --recursive git reset --hard
    git submodule update --init --recursive
    
    find . -type f -name "CMakeCache.txt" -delete
    --------------------------------------------------

FAQ
    1.Configuration ran into mess
      If you encounter the following error message, just reset all the configuration and retrigger the building.
      --------------------------------------------------
          ERROR: Feature "openssl": Forcing to "ON" breaks its condition:
          QT_FEATURE_openssl_runtime OR QT_FEATURE_openssl_linked
      Condition values dump:
          QT_FEATURE_openssl_runtime = "OFF"
          QT_FEATURE_openssl_linked = "OFF"
      
      ERROR: Feature "sql_psql": Forcing to "ON" breaks its condition:
          PostgreSQL_FOUND
      Condition values dump:
          PostgreSQL_FOUND = "FALSE"
      --------------------------------------------------