if(NOT spirv-cross-c-shared_FOUND AND Vulkan_FOUND)
    if(NOT Vulkan_INCLUDE_DIR OR NOT VULKAN_BIN_PATH OR NOT VULKAN_LIB_PATH)
        message(FATAL_ERROR "the Vulkan SDK paths aren't in the CMake cache")
    endif()

    include("${CMAKE_CURRENT_LIST_DIR}/paths.cmake")
    check_path("${Vulkan_INCLUDE_DIR}")

    add_library(spirv-cross-c-shared SHARED IMPORTED)
    set_property(TARGET spirv-cross-c-shared PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${Vulkan_INCLUDE_DIR}/spirv_cross")
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set_target_properties(spirv-cross-c-shared PROPERTIES
            IMPORTED_LOCATION "${VULKAN_BIN_PATH}/spirv-cross-c-shared.dll"
            IMPORTED_IMPLIB "${VULKAN_LIB_PATH}/spirv-cross-c-shared.lib"
        )
    endif()
    set(spirv-cross-c-shared_FOUND TRUE)
endif()
