# Version override for Qt binaries vs installation paths
# This file is included AFTER each project() command via CMAKE_PROJECT_INCLUDE
#
# Goal:
# - Binary/library version: 6.8.100 (to indicate security fixes)
# - Header installation paths: 6.8.3 (to maintain compatibility)
#
# Strategy:
# 1. Save the binary version (6.8.100) before overriding
# 2. Override set_target_properties to use binary version for VERSION property
# 3. Override PROJECT_VERSION to 6.8.3 for installation paths

if(PROJECT_VERSION VERSION_EQUAL "6.8.100")
    # Save the binary version for library versioning
    set(QT_BINARY_VERSION "6.8.100" CACHE INTERNAL "Qt binary version")
    set(QT_BINARY_VERSION_MAJOR "6" CACHE INTERNAL "Qt binary major version")
    set(QT_BINARY_VERSION_MINOR "8" CACHE INTERNAL "Qt binary minor version")
    set(QT_BINARY_VERSION_PATCH "100" CACHE INTERNAL "Qt binary patch version")

    # Override set_target_properties to intercept VERSION property
    if(NOT COMMAND _qt_original_set_target_properties)
        # Save the original function (only once)
        macro(_qt_original_set_target_properties)
            _set_target_properties(${ARGN})
        endmacro()

        # Rename the built-in command
        function(set_target_properties)
            set(_new_args)
            set(_found_version FALSE)
            set(_i 0)

            # Parse through arguments
            foreach(_arg IN LISTS ARGN)
                if(_arg STREQUAL "VERSION")
                    set(_found_version TRUE)
                    list(APPEND _new_args ${_arg})
                elseif(_found_version)
                    # Replace PROJECT_VERSION with QT_BINARY_VERSION in the version value
                    string(REPLACE "${PROJECT_VERSION}" "${QT_BINARY_VERSION}" _arg "${_arg}")
                    list(APPEND _new_args ${_arg})
                    set(_found_version FALSE)
                else()
                    list(APPEND _new_args ${_arg})
                endif()
            endforeach()

            # Call original with modified arguments
            _qt_original_set_target_properties(${_new_args})
        endfunction()
    endif()

    # Override PROJECT_VERSION to 6.8.3 for installation paths (headers, cmake configs, etc.)
    set(PROJECT_VERSION "6.8.3")
    set(PROJECT_VERSION_MAJOR "6")
    set(PROJECT_VERSION_MINOR "8")
    set(PROJECT_VERSION_PATCH "3")
    set(PROJECT_VERSION_TWEAK "")

    # Set in parent scope as well
    set(PROJECT_VERSION "6.8.3" PARENT_SCOPE)
    set(PROJECT_VERSION_MAJOR "6" PARENT_SCOPE)
    set(PROJECT_VERSION_MINOR "8" PARENT_SCOPE)
    set(PROJECT_VERSION_PATCH "3" PARENT_SCOPE)
    set(PROJECT_VERSION_TWEAK "" PARENT_SCOPE)

    message(STATUS "[${PROJECT_NAME}] Binary version: 6.8.100, Installation paths: 6.8.3")
endif()
