include_guard(GLOBAL)

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR NOT CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "this toolchain file is only supported on 64-bit x86 Windows host systems")
endif()

set(WINDOWS_SDK_REGISTRY_KEY "HKLM/SOFTWARE/WOW6432Node/Microsoft/Microsoft SDKs/Windows/v10.0")
cmake_host_system_information(RESULT WINDOWS_SDK_INSTALL_PATH
    QUERY WINDOWS_REGISTRY ${WINDOWS_SDK_REGISTRY_KEY}
    VALUE InstallationFolder
)
cmake_host_system_information(RESULT WINDOWS_SDK_VERSION
    QUERY WINDOWS_REGISTRY ${WINDOWS_SDK_REGISTRY_KEY}
    VALUE ProductVersion
)

set(WINDOWS_SDK_LIB_PATH "${WINDOWS_SDK_INSTALL_PATH}/Lib/${WINDOWS_SDK_VERSION}")
set(WINDOWS_SDK_INCLUDE_PATH "${WINDOWS_SDK_INSTALL_PATH}/Include/${WINDOWS_SDK_VERSION}")

add_standard_link_directories("${WINDOWS_SDK_LIB_PATH}/ucrt/x64"
    "${WINDOWS_SDK_LIB_PATH}/um/x64"
)
add_standard_include_directories("${WINDOWS_SDK_INCLUDE_PATH}/cppwinrt"
    "${WINDOWS_SDK_INCLUDE_PATH}/shared"
    "${WINDOWS_SDK_INCLUDE_PATH}/ucrt"
    "${WINDOWS_SDK_INCLUDE_PATH}/um"
    "${WINDOWS_SDK_INCLUDE_PATH}/winrt"
)
