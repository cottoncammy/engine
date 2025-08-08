include_guard(GLOBAL)

macro(add_standard_link_directories)
    list(APPEND CMAKE_C_STANDARD_LINK_DIRECTORIES ${ARGV})
    list(APPEND CMAKE_C_STANDARD_LINK_DIRECTORIES ${ARGV})
endmacro()

macro(add_standard_include_directories)
    list(APPEND CMAKE_C_STANDARD_INCLUDE_DIRECTORIES ${ARGV})
    list(APPEND CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${ARGV})
endmacro()

macro(set_compiler COMPILER_PATH)
    set(CMAKE_C_COMPILER "${COMPILER_PATH}")
    set(CMAKE_CXX_COMPILER "${COMPILER_PATH}")
endmacro()

include("${CMAKE_CURRENT_LIST_DIR}/msvc-clang-ninja.toolchain.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/windows-sdk.toolchain.cmake")
