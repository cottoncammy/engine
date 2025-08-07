function(find_sdl3_library OUT_VAR)
    find_library(${OUT_VAR}
        NAMES SDL3-static.a SDL3-static.lib
        OPTIONAL
        NO_CMAKE_ENVIRONMENT_PATH
        NO_SYSTEM_ENVIRONMENT_PATH
    )
endfunction()

if(SDL3_FIND_QUIETLY)
    set(SDL3_FIND_QUIET QUIET)
endif()

# next, try to search for the package in Config mode
if(NOT SDL3_FOUND)
    if(SDL3_FIND_VERSION_EXACT)
        set(SDL3_FIND_EXACT EXACT)
    endif()

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

    if (SDL3_FOUND)
        # make sure the package found has SDL3-static.lib
        set(SDL3_ROOT "${PROJECT_BINARY_DIR}/vendor/SDL")
        find_sdl3_library(SDL3_FOUND)
        unset(SDL3_ROOT)
    endif()
endif()

# finally, just build it from source
if(NOT SDL3_FOUND AND SDL3_FIND_REQUIRED)
    set(SDL_DEPS_SHARED OFF)
    set(SDL_SHARED OFF)
    set(SDL_TEST_LIBRARY OFF)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL" EXCLUDE_FROM_ALL)
    set(SDL3_FOUND TRUE)
endif()

if(SDL3_FOUND)
    set(SDL3_LIBDIR "${SDL3_BINARY_DIR}")
    set(SDL3_VERSION ${SDL3_PROJECT_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL3
    REQUIRED_VARS SDL3_LIBDIR
    VERSION_VAR SDL3_VERSION
)
