find_package(PkgConfig QUIET)

if(PKG_CONFIG_FOUND)
    if(SDL3_FIND_QUIETLY)
        set(PC_FIND_QUIET QUIET)
    endif()

    if(SDL3_FIND_VERSION_EXACT)
        set(PC_FIND_MODULE_SPEC_SUFFIX =${SDL3_FIND_VERSION})
    else()
        set(PC_FIND_MODULE_SPEC_SUFFIX >=${SDL3_FIND_VERSION)
    endif()

    pkg_check_modules(SDL3 ${PC_FIND_QUIET} SDL3${PC_FIND_MODULE_SPEC_SUFFIX})

    if(SDL3_FOUND)
        add_library(SDL3::SDL3 UNKNOWN IMPORTED)
        set_target_properties(SDL3::SDL3 PROPERTIES
            IMPORTED_LOCATION "${SDL3_LIBDIR}"
            INTERFACE_INCLUDE_DIRECTORIES "${SDL3_INCLUDE_DIRS}"
            INTERFACE_LINK_LIBRARIES "${SDL3_LINK_LIBRARIES}"
            IMPORTED_LINK_INTERFACE_LANGUAGES C;CXX
            IMPORTED_IMPLIB "${SDL3_LIBDIR}"
            IMPORTED_SONAME "${SDL3_FIND_VERSION_MAJOR}"
        )

        mark_as_advanced(FORCE SDL3_LIBDIR SDL3_VERSION)
    endif()
elseif(SDL3_FIND_REQUIRED)
    set(SDL_DEPS_SHARED OFF)
    set(SDL_SHARED OFF)
    set(SDL_TEST_LIBRARY OFF)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL" EXCLUDE_FROM_ALL)

    set(SDL3_VERSION ${SDL3_PROJECT_VERSION})
    set(SDL3_LIBDIR ${SDL3_BINARY_DIR})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL3
    REQUIRED_VARS SDL3_LIBDIR
    VERSION_VAR SDL3_VERSION
)
