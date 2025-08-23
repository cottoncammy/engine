cmake_minimum_required(VERSION 3.50 FATAL_ERROR)

project(submachine VERSION 0.1.0 LANGUAGES C)

# check build config
if(NOT WIN32 OR NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "only builds targeting Windows x64 are supported")
endif()

if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang" OR NOT CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
    message(FATAL_ERROR "only the clang-cl C compiler is supported")
endif()

if(NOT CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
    message(FATAL_ERROR "only the Ninja Multi-Config build generator is supported")
endif()

if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "including this project or adding it as a subproject isn't supported")
endif()

set(CMAKE_CONFIGURATION_TYPES "Debug;Release;ReleaseASAN")
set(CMAKE_DEFAULT_BUILD_TYPE Debug)

if(NOT BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS OFF)
elseif(BUILD_SHARED_LIBS)
    message(FATAL_ERROR "shared library builds aren't supported")
endif()

# options
option(SUBMACHINE_INSTALL "Enable installation of submachine binary and data" OFF)

# add binary
add_executable(submachine)

# find dependencies or build them
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(WANTED_SDL3_VERSION 3.2.0)
set(WANTED_SDL3_SHADERCROSS_VERSION 3.0.0)

find_package(SDL3 ${WANTED_SDL3_VERSION} QUIET)
if(NOT SDL3_FOUND)
    set(SDL_DEPS_SHARED OFF)
    set(SDL_INSTALL ON)
    set(SDL_HIDAPI OFF)
    set(SDL_SHARED OFF)
    set(SDL_TEST_LIBRARY OFF)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL" EXCLUDE_FROM_ALL)
endif()

find_package(SDL3_shadercross ${WANTED_SDL3_SHADERCROSS_VERSION} QUIET NO_CMAKE_FIND_ROOT_PATH)
if(NOT SDL3_shadercross_FOUND)
    # can't build from source for the host to run when cross-compiling
    if(CMAKE_CROSSCOMPILING)
        message(FATAL_ERROR "SDL3_shadercross wasn't found and can't be built for the host during cross-compilation")
    endif()
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-SDL3-shadercross.cmake")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-wuffs.cmake")

# configure binary
target_compile_features(submachine PRIVATE c_std_11)
set_target_properties(submachine PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS ON
    COMPILE_WARNING_AS_ERROR ON
    EXPORT_COMPILE_COMMANDS ON
    COMPILE_OPTIONS $<$<CONFIG:ReleaseASAN>:-fsanitize=address>
    MSVC_DEBUG_INFORMATION_FORMAT $<$<CONFIG:Debug,ReleaseASAN>:ProgramDatabase>
)
target_link_options(submachine PRIVATE
    $<$<CONFIG:ReleaseASAN>:-fsanitize=address>
    $<$<AND:$<CONFIG:Debug,ReleaseASAN>,$<PLATFORM_ID:Windows>>:/debug>
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sm_build_config.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/sm_build_config.h"
    NO_SOURCE_PERMISSIONS
    @ONLY
)

target_sources(submachine
    PRIVATE
        FILE_SET submachine_headers
        TYPE HEADERS
        BASE_DIRS
            "${CMAKE_CURRENT_BINARY_DIR}"
            src
        FILES
            "${CMAKE_CURRENT_BINARY_DIR}/sm_build_config.h"
            src/sm_assert.h
            src/sm_assets.h
            src/sm_entrypoint.h
            src/sm_gpu.h
    PRIVATE
        src/sm_assets.c
        src/sm_entrypoint.c
        src/sm_gpu.c
)

target_link_libraries(submachine PRIVATE
    SDL3::SDL3
    wuffs_base
)

if(WIN32)
    target_link_libraries(submachine PRIVATE pathcch $<$<CONFIG:ReleaseASAN>:clang_rt.asan-x86_64>)
endif()

# compile shaders after building
set(SHADERCROSS_INPUT_FILES
    assets/shaders/color.frag.hlsl
    assets/shaders/triangle.vert.hlsl
)
list(TRANSFORM SHADERCROSS_INPUT_FILES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")

set(SHADERS_INSTALL_PATH "$<TARGET_FILE_DIR:submachine>/assets")
add_custom_command(TARGET submachine
    POST_BUILD
    COMMAND cmake -E make_directory "${SHADERS_INSTALL_PATH}"
    COMMENT "Making dir ${SHADERS_INSTALL_PATH}"
    VERBATIM
)
set(SHADERCROSS_OUTPUT_FILES)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/paths.cmake")
foreach(SHADERCROSS_INPUT_FILE IN LISTS SHADERCROSS_INPUT_FILES)
    cmake_path(GET SHADERCROSS_INPUT_FILE FILENAME SHADERCROSS_INPUT_FILENAME)
    get_relative_path(SHADERCROSS_INPUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/assets/shaders" SHADERCROSS_INPUT_FILE_RELATIVE_PATH)
    cmake_path(REMOVE_EXTENSION
        SHADERCROSS_INPUT_FILENAME
        LAST_ONLY
        OUTPUT_VARIABLE SHADERCROSS_INPUT_FILE_STEM
    )

    foreach(SHADER_FORMAT JSON DXIL SPIRV)
        set(SHADERCROSS_OUTPUT_FILE ${SHADERCROSS_INPUT_FILE_STEM})
        if(SHADER_FORMAT STREQUAL JSON)
            string(APPEND SHADERCROSS_OUTPUT_FILE ".json")
        elseif(SHADER_FORMAT STREQUAL DXIL)
            string(APPEND SHADERCROSS_OUTPUT_FILE ".dxil")
        else()
            string(APPEND SHADERCROSS_OUTPUT_FILE ".spv")
        endif()
        list(APPEND SHADERCROSS_OUTPUT_FILES "${SHADERCROSS_OUTPUT_FILE}")

        add_custom_command(TARGET submachine
            POST_BUILD
            COMMAND shadercross "${SHADERCROSS_INPUT_FILE}" -o "${SHADERS_INSTALL_PATH}/${SHADERCROSS_OUTPUT_FILE}"
            COMMENT "Compiling ${SHADERCROSS_INPUT_FILE} to ${SHADERCROSS_OUTPUT_FILE}"
            VERBATIM
        )
    endforeach()
endforeach()

# installation
if(SUBMACHINE_INSTALL)
    include(GNUInstallDirs)
    set(CMAKE_CONFIG_INSTALL_PATH "cmake")
    set(ASSETS_INSTALL_PATH "${CMAKE_INSTALL_DATADIR}/submachine/assets")

    install(TARGETS submachine
        EXPORT submachine-targets
        CONFIGURATIONS Release
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    )
    install(EXPORT submachine-targets
        DESTINATION "${CMAKE_CONFIG_INSTALL_PATH}"
        NAMESPACE cottoncammy::
        FILE submachine-targets.cmake
        CONFIGURATIONS Release
    )

    # install shaders
    list(TRANSFORM SHADERCROSS_OUTPUT_FILES PREPEND "${SHADERS_INSTALL_PATH}/")
    install(FILES ${SHADERCROSS_OUTPUT_FILES}
        DESTINATION "${ASSETS_INSTALL_PATH}"
        CONFIGURATIONS Release
    )

    # install CMake config
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        submachine-config-version.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY ExactVersion
    )
    configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/cmake/submachine-config.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/submachine-config.cmake"
        INSTALL_DESTINATION "${CMAKE_CONFIG_INSTALL_PATH}"
        NO_SET_AND_CHECK_MACRO
    )
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/submachine-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/submachine-config-version.cmake"
        DESTINATION "${CMAKE_CONFIG_INSTALL_PATH}"
        CONFIGURATIONS Release
    )
endif()
