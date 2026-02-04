# Version override for all Qt submodules
# This file is included before each project() command via CMAKE_PROJECT_INCLUDE_BEFORE

if(DEFINED QT_REPO_MODULE_VERSION)
    # Map old versions to new versions
    if(QT_REPO_MODULE_VERSION STREQUAL "6.8.3")
        set(QT_REPO_MODULE_VERSION "6.8.33")
        message(STATUS "Overriding module version: 6.8.3 -> 6.8.33")
    endif()
endif()
