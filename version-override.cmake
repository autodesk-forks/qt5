# Version override for all Qt submodules
# This file is included by each project() command

# Override PROJECT_VERSION if it's 6.8.3
if(PROJECT_VERSION STREQUAL "6.8.3")
    set(PROJECT_VERSION "6.83.1")
    set(PROJECT_VERSION_MAJOR 6)
    set(PROJECT_VERSION_MINOR 83)
    set(PROJECT_VERSION_PATCH 1)
    set(PROJECT_VERSION_TWEAK "")
    message(STATUS "Overriding ${PROJECT_NAME} version: 6.8.3 -> 6.83.1")
endif()
