cmake_minimum_required(VERSION 3.50 FATAL_ERROR)

project(engine VERSION 0.0.0 LANGUAGES C)

# check build config
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows" OR NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "only builds targeting 64-bit x86 Windows are supported")
endif()

if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang" OR NOT CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    message(FATAL_ERROR "only the clang-cl C compiler is supported")
endif()

if(NOT CMAKE_GENERATOR STREQUAL "Ninja")
    message(FATAL_ERROR "only the Ninja build generator is supported")
endif()

if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "including this project or adding it as a subproject isn't supported")
endif()

if(NOT BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF)
elseif(BUILD_SHARED_LIBS)
    message(FATAL_ERROR "shared library builds aren't supported")
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# find dependencies or build them
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(WANTED_SDL3_VERSION 3.2)
set(WANTED_SDL3_SHADERCROSS_VERSION 3.0)

find_package(SDL3 ${WANTED_SDL3_VERSION} QUIET)
if(NOT SDL3_FOUND)
    set(SDL_DEPS_SHARED OFF)
    set(SDL_INSTALL ON)
    set(SDL_HIDAPI OFF)
    set(SDL_SHARED OFF)
    set(SDL_TEST_LIBRARY OFF)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL")
endif()

find_package(SDL3_shadercross ${WANTED_SDL3_SHADERCROSS_VERSION} QUIET NO_CMAKE_FIND_ROOT_PATH)
if(NOT SDL3_shadercross_FOUND)
    # can't build from source for the host machine to run when cross-compiling
    if(CMAKE_CROSSCOMPILING)
        message(FATAL_ERROR "SDL3_shadercross was not found and cannot be built for the host system during cross-compilation")
    endif()

    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-SDL3-shadercross.cmake")
endif()

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

# compile shaders
set(SHADERCROSS_INPUT_FILES
    assets/shaders/foo.vert.hlsl
)
set(SHADERCROSS_OUTPUT_FILES)

foreach(SHADERCROSS_INPUT_FILE IN LISTS SHADERCROSS_INPUT_FILES)
    cmake_path(APPEND CMAKE_CURRENT_SOURCE_DIR "${SHADERCROSS_INPUT_FILE}" OUTPUT_VARIABLE SHADERCROSS_INPUT_FILE)
    foreach(SHADER_FORMAT DXIL SPIRV)
        cmake_path(GET SHADERCROSS_INPUT_FILE FILENAME SHADERCROSS_INPUT_FILENAME)
        cmake_path(REMOVE_EXTENSION
            SHADERCROSS_INPUT_FILENAME
            LAST_ONLY
            OUTPUT_VARIABLE SHADERCROSS_OUTPUT_FILENAME
        )
        set(SHADERCROSS_OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/shaders/${SHADERCROSS_OUTPUT_FILENAME}.$<IF:$<STREQUAL:${SHADER_FORMAT},DXIL>,dxil,spv>")
        list(APPEND SHADERCROSS_OUTPUT_FILES "${SHADERCROSS_OUTPUT_FILE}")

        add_custom_command(COMMAND
            shadercross "${SHADERCROSS_INPUT_FILE}" -o "${SHADERCROSS_OUTPUT_FILE}"
            OUTPUT "${SHADERCROSS_OUTPUT_FILE}"
            DEPENDS "${SHADERCROSS_INPUT_FILE}"
            COMMENT "Compiling ${SHADERCROSS_INPUT_FILE} to ${SHADERCROSS_OUTPUT_FILE}"
            VERBATIM
        )
    endforeach()
endforeach()

add_custom_target(shaders DEPENDS ${SHADERCROSS_OUTPUT_FILES})
add_dependencies(engine shaders)

# install engine binary
include(GNUInstallDirs)
set(CONFIG_INSTALL_DIR "cmake")

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
# install shaders
install(FILES ${SHADERCROSS_OUTPUT_FILES} DESTINATION "${CMAKE_INSTALL_DATADIR}/shaders")

# install CMake config files
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
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/engine-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/engine-config-version.cmake"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

# export engine targets
export(EXPORT engine-targets
    NAMESPACE cottoncammy::
    FILE "${CMAKE_CURRENT_BINARY_DIR}/engine-targets.cmake"
)
export(PACKAGE engine)
