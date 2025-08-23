macro(enable_sdl_shadercross_vendored_dependencies)
    set(SDLSHADERCROSS_SPIRVCROSS_SHARED OFF)
    set(SDLSHADERCROSS_VENDORED_DEPENDENCIES ON)
endmacro()

set(SDL3_shadercross_SOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL_shadercross")

# the Windows SDK includes dxcompiler and dxil
if(NOT WINDOWS_SDK_INCLUDE_PATH OR NOT WINDOWS_SDK_BIN_PATH OR NOT WINDOWS_SDK_LIB_PATH)
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        message(FATAL_ERROR "the Windows SDK paths aren't in the CMake cache")
    else()
        enable_sdl_shadercross_vendored_dependencies()
    endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    # copy the binaries to where SDL_shadercross expects them
    set(DirectXShaderCompiler_INSTALL_PATH "${SDL3_shadercross_SOURCE_PATH}/external/DirectXShaderCompiler-binaries")
    file(INSTALL
        "${WINDOWS_SDK_INCLUDE_PATH}/um/dxcapi.h"
        "${WINDOWS_SDK_BIN_PATH}/x64/dxcompiler.dll"
        "${WINDOWS_SDK_LIB_PATH}/um/x64/dxcompiler.lib"
        "${WINDOWS_SDK_BIN_PATH}/x64/dxil.dll"
        DESTINATION "${DirectXShaderCompiler_INSTALL_PATH}"
    )
endif()

if(NOT SDLSHADERCROSS_VENDORED_DEPENDENCIES)
    # the Vulkan SDK includes spirv-cross-c-shared
    set(WANTED_VULKAN_VERSION 1.4.321)
    find_package(Vulkan ${WANTED_VULKAN_VERSION} QUIET COMPONENTS SPIRV-Tools)
    if(Vulkan_FOUND)
        # set cache variables so Findspirv_cross_c_shared.cmake can use them
        set(Vulkan_FOUND ${Vulkan_FOUND} CACHE BOOL "")
        cmake_path(GET Vulkan_LIBRARY PARENT_PATH VULKAN_LIB_PATH)
        set(VULKAN_LIB_PATH "${VULKAN_LIB_PATH}" CACHE PATH "")
        cmake_path(GET VULKAN_LIB_PATH PARENT_PATH VULKAN_INSTALL_PATH)

        include("${CMAKE_CURRENT_LIST_DIR}/paths.cmake")
        cache_and_check_path(VULKAN_BIN_PATH "${VULKAN_INSTALL_PATH}/Bin")
    elseif(NOT Vulkan_FOUND)
        enable_sdl_shadercross_vendored_dependencies()
    endif()
endif()

if(SDL3_SDL3-static_FOUND OR TARGET SDL3::SDL3-static)
    set(SDLSHADERCROSS_CLI_STATIC ON)
endif()
add_subdirectory("${SDL3_shadercross_SOURCE_PATH}" EXCLUDE_FROM_ALL)
