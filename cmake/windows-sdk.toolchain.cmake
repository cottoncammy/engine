include_guard(GLOBAL)

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR NOT CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "this toolchain file is only supported on 64-bit x86 Windows host systems")
endif()

set(WINDOWS_SDK_REGISTRY_KEY "HKLM/SOFTWARE/Microsoft/Windows Kits/Installed Roots")
cmake_host_system_information(RESULT WINDOWS_SDK_INSTALL_PATH
    QUERY WINDOWS_REGISTRY ${WINDOWS_SDK_REGISTRY_KEY}
    VALUE KitsRoot10
    VIEW 64
    ERROR_VARIABLE REGISTRY_QUERY_RESULT
)
if(NOT WINDOWS_SDK_INSTALL_PATH OR REGISTRY_QUERY_RESULT)
    message(FATAL_ERROR "failed to query the Windows registry for installed Windows SDK root path: ${REGISTRY_QUERY_RESULT}")
endif()

cmake_host_system_information(RESULT WINDOWS_SDK_ROOTS
    QUERY WINDOWS_REGISTRY ${WINDOWS_SDK_REGISTRY_KEY}
    SUBKEYS
    VIEW 64
    ERROR_VARIABLE REGISTRY_QUERY_RESULT
)
if(NOT WINDOWS_SDK_ROOTS OR REGISTRY_QUERY_RESULT)
    message(FATAL_ERROR "failed to query the Windows registry for the list of installed Windows SDK versions: ${REGISTRY_QUERY_RESULT}")
endif()

list(LENGTH WINDOWS_SDK_ROOTS WINDOWS_SDK_ROOTS_LENGTH)
if(WINDOWS_SDK_ROOTS_LENGTH EQUAL 0)
    message(FATAL_ERROR "no Windows SDKs were found in the registry")
endif()

cmake_path(NORMAL_PATH WINDOWS_SDK_INSTALL_PATH)
list(SORT WINDOWS_SDK_ROOTS ORDER DESCENDING)
list(GET WINDOWS_SDK_ROOTS 0 WINDOWS_SDK_VERSION)

include("${CMAKE_CURRENT_LIST_DIR}/check-paths.cmake")
cache_and_check_path(WINDOWS_SDK_LIB_PATH "${WINDOWS_SDK_INSTALL_PATH}/Lib/${WINDOWS_SDK_VERSION}")
cache_and_check_path(WINDOWS_SDK_BIN_PATH "${WINDOWS_SDK_INSTALL_PATH}/bin/${WINDOWS_SDK_VERSION}")
cache_and_check_path(WINDOWS_SDK_INCLUDE_PATH "${WINDOWS_SDK_INSTALL_PATH}/Include/${WINDOWS_SDK_VERSION}")

add_standard_link_directories("${WINDOWS_SDK_LIB_PATH}/ucrt/x64"
    "${WINDOWS_SDK_LIB_PATH}/um/x64"
)
add_standard_include_directories("${WINDOWS_SDK_INCLUDE_PATH}/cppwinrt"
    "${WINDOWS_SDK_INCLUDE_PATH}/shared"
    "${WINDOWS_SDK_INCLUDE_PATH}/ucrt"
    "${WINDOWS_SDK_INCLUDE_PATH}/um"
    "${WINDOWS_SDK_INCLUDE_PATH}/winrt"
)
