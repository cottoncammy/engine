cmake_minimum_required(VERSION 3.50 FATAL_ERROR)

project(engine VERSION 0.0.0 LANGUAGES C)

# check build config
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows" OR NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "only builds targeting 64-bit x86 Windows are supported")
endif()

if($<NOT:$<C_COMPILER_ID:Clang>> OR NOT CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    message(FATAL_ERROR "only the clang-cl C compiler is supported")
endif()

if(NOT CMAKE_GENERATOR STREQUAL "Ninja")
    message(FATAL_ERROR "only the Ninja build generator is supported")
endif()

if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "including this project or adding it as a subproject isn't supported")
endif()

if(NOT DEFINED BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF)
elseif(BUILD_SHARED_LIBS)
    message(FATAL_ERROR "shared library builds aren't supported")
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(NOT CMAKE_EXPORT_PACKAGE_REGISTRY)
    set(CMAKE_EXPORT_PACKAGE_REGISTRY ON)
endif()

# find dependencies
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

set(WANTED_SDL3_VERSION 3.2)
set(WANTED_SDL3_SHADERCROSS_VERSION 3.0)

find_package(SDL3 ${WANTED_SDL3_VERSION} REQUIRED)
find_package(SDL3_shadercross ${WANTED_SDL3_SHADERCROSS_VERSION} REQUIRED)

# configure engine binary
add_executable(engine)

target_compile_features(engine PRIVATE c_std_11)
set_target_properties(engine PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS ON
    COMPILE_WARNING_AS_ERROR ON
    EXPORT_COMPILE_COMMANDS ON
)

target_sources(engine
    PRIVATE
        FILE_SET engine_headers
        TYPE HEADERS
        BASE_DIRS src
        FILES
            src/main.h
    PRIVATE
        src/main.c
)
target_link_libraries(engine PRIVATE
    SDL3::SDL3
)

# install engine binary
include(GNUInstallDirs)
set(CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/engine")

install(TARGETS engine
    EXPORT engine-targets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
install(EXPORT engine-targets
    DESTINATION "${CONFIG_INSTALL_DIR}"
    NAMESPACE cottoncammy::
    FILE engine-targets.cmake
)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    engine-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY ExactVersion
)
configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/cmake/engine-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config.cmake"
    INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
    NO_SET_AND_CHECK_MACRO
)

install(FILES "${CMAKE_CURRENT_LIST_DIR}/cmake/FindSDL3.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/cmake/FindSDL3_shadercross.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config-version.cmake"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

# export engine targets
export(EXPORT engine-targets
    NAMESPACE cottoncammy::
    FILE "${CMAKE_CURRENT_BINARY_DIR}/engine-targets.cmake"
)
export(PACKAGE engine)
