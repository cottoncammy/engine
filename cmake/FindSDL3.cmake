if(SDL3_FIND_QUIETLY)
    set(SDL3_FIND_QUIET QUIET)
endif()

if(SDL3_FIND_VERSION_EXACT)
    set(SDL3_FIND_EXACT EXACT)
endif()

# try to search for the package in Config mode
find_package(SDL3
    ${SDL3_FIND_VERSION}
    ${SDL3_FIND_EXACT}
    ${SDL3_FIND_QUIET}
    CONFIG
    NO_CMAKE_ENVIRONMENT_PATH
    NO_SYSTEM_ENVIRONMENT_PATH
)
unset(SDL3_FIND_EXACT)
unset(SDL3_FIND_QUIET)

# just build it from source
if(NOT SDL3_FOUND AND SDL3_FIND_REQUIRED)
    set(SDL_DEPS_SHARED OFF)
    set(SDL_SHARED OFF)
    set(SDL_TEST_LIBRARY OFF)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL" EXCLUDE_FROM_ALL)

    set(SDL3_FOUND TRUE)
    set(SDL3_INSTALL_PATH "${SDL3_BINARY_DIR}")
    set(SDL3_VERSION 3.2.20)
elseif(SDL3_FOUND)
    get_target_property(SDL3_INSTALL_PATH ${SDL3_LIBRARIES} LOCATION)
    set(SDL3_VERSION ${PACKAGE_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL3
    REQUIRED_VARS SDL3_INSTALL_PATH
    VERSION_VAR SDL3_VERSION
)
