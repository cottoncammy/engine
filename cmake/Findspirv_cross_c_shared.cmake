if(Vulkan_FOUND)
    add_library(spirv-cross-c-shared SHARED IMPORTED)
    set_target_properties(spirv-cross-c-shared PROPERTIES
        IMPORTED_LOCATION "${VULKAN_BIN_PATH}/spirv-cross-c-shared${CMAKE_SHARED_LIBRARY_SUFFIX}"
        INTERFACE_INCLUDE_DIRECTORIES "${Vulkan_INCLUDE_DIR}/spirv_cross"
    )
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set_property(TARGET spirv-cross-c-shared PROPERTY IMPORTED_IMPLIB "${VULKAN_LIB_PATH}/spirv-cross-c-shared.lib")
    endif()
    set(spirv-cross-c-shared_FOUND TRUE)
endif()
