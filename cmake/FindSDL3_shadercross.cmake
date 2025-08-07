function(enable_sdl_shadercross_vendored_dependencies)
    if(NOT ARGC EQUAL 0)
        message(FATAL_ERROR "unknown args were passed to enable_sdl_shadercross_vendored_dependencies")
    endif()
    set(SDLSHADERCROSS_SPIRVCROSS_SHARED OFF PARENT_SCOPE)
    set(SDLSHADERCROSS_VENDORED_DEPENDENCIES ON PARENT_SCOPE)
endfunction()

if(SDL3_shadercross_FIND_QUIETLY)
    set(SDL3_shadercross_FIND_QUIET QUIET)
endif()

if(SDL3_shadercross_FIND_VERSION_EXACT)
    set(SDL3_shadercross_FIND_EXACT EXACT)
endif()

# try to find SDL3_shadercross by searching in Config mode
find_package(SDL3_shadercross
    ${SDL3_shadercross_FIND_VERSION}
    ${SDL3_shadercross_FIND_EXACT}
    ${SDL3_shadercross_FIND_QUIET}
    CONFIG
)

# just build it from source
if(NOT SDL3_shadercross_FOUND AND SDL3_shadercross_FIND_REQUIRED)
    set(SDL3_shadercross_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL_shadercross")

    # determine whether we need to enable vendored dependencies
    # the Windows SDK required to build this project when targeting Windows includes dxcompiler and dxil
    if(NOT WINDOWS_SDK_INCLUDE_PATH OR NOT WINDOWS_SDK_BIN_PATH OR NOT WINDOWS_SDK_LIB_PATH)
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
            message(FATAL_ERROR "the Windows SDK wasn't located on the host system")
        else()
            enable_sdl_shadercross_vendored_dependencies()
        endif()
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        # SDL_shadercross includes a FindDirectXShaderCompiler.cmake module that would override any custom logic here
        # instead, just copy the binaries to where SDL_shadercross expects them
        set(DirectXShaderCompiler_INSTALL_PATH "${SDL3_shadercross_SOURCE_DIR}/external/DirectXShaderCompiler-binaries")
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
        include(FindVulkan)
        find_package(Vulkan COMPONENTS SPIRV-Tools dxc)
        if(Vulkan_FOUND)
            # set cache variables so Findspirv_cross_c_shared.cmake can use them
            set(Vulkan_FOUND ${Vulkan_FOUND} CACHE BOOL "")
            cmake_path(GET Vulkan_LIBRARY PARENT_PATH VULKAN_LIB_PATH)
            set(VULKAN_LIB_PATH "${VULKAN_LIB_PATH}" CACHE PATH "")
            cmake_path(GET VULKAN_LIB_PATH PARENT_PATH VULKAN_INSTALL_PATH)
            set(VULKAN_BIN_PATH "${VULKAN_INSTALL_PATH}/Bin" CACHE PATH "")
        else()
            enable_sdl_shadercross_vendored_dependencies()
        endif()
    endif()

    if(SDL3_SDL3-static_FOUND OR TARGET SDL3::SDL3-static)
        set(SDLSHADERCROSS_CLI_STATIC ON)
    endif()

    add_subdirectory("${SDL3_shadercross_SOURCE_DIR}" EXCLUDE_FROM_ALL)
    set(SDL3_shadercross_INSTALL_PATH "${SDL3_shadercross_BINARY_DIR}")
    set(SDL3_shadercross_VERSION 3.0.0)
elseif(SDL3_shadercross_FOUND)
    set(SDL3_shadercross_INSTALL_PATH TODO)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL3_shadercross
    REQUIRED_VARS SDL3_shadercross_INSTALL_PATH
    VERSION_VAR SDL3_shadercross_VERSION
)
