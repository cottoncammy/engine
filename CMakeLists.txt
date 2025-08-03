cmake_minimum_required(VERSION 3.50 FATAL_ERROR)

project(engine VERSION 0.0.0 LANGUAGES C)

if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "")
endif()

if($<NOT:$<C_COMPILER_ID:Clang>> OR NOT CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    message(FATAL_ERROR "")
endif()

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(FATAL_ERROR "")
endif()

if(NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

if(NOT DEFINED BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
elseif(BUILD_SHARED_LIBS)
    message(FATAL_ERROR "")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

set(SDL3_VERSION 3.2)
find_package(SDL3 ${MIN_SDL3_VERSION} REQUIRED)

add_executable(engine WIN32)

target_compile_features(engine PRIVATE c_std_11)

set_target_properties(engine PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS ON
    COMPILE_WARNING_AS_ERROR ON
    EXPORT_COMPILE_COMMANDS ON
    MSVC_RUNTIME_LIBRARY MultiThreaded$<$<CONFIG:Debug>:Debug>
)

target_sources(engine
    PRIVATE
        FILE_SET engine_headers
        TYPE HEADERS
        BASE_DIRS src
        FILES
            src/main.h

        FILES
            src/main.c
)

target_link_libraries(engine PRIVATE
    SDL3::SDL3
)

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
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY ExactVersion
)

configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/cmake/engine-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config.cmake"
    INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
    NO_SET_AND_CHECK_MACRO
)

install(FILES "${CMAKE_CURRENT_LIST_DIR}/cmake/FindSDL3.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config-version.cmake"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

export(EXPORT engine-targets
    NAMESPACE cottoncammy::
    FILE "${CMAKE_CURRENT_BINARY_DIR}/engine-targets.cmake"
)

set(CMAKE_EXPORT_PACKAGE_REGISTRY ON)
export(PACKAGE engine)
set(CMAKE_EXPORT_PACKAGE_REGISTRY OFF)
