include_guard(GLOBAL)

function(add_standard_link_directories)
    if(ARGC EQUAL 0)
        message(FATAL_ERROR "no args were passed to add_standard_link_directories")
    endif()

    list(APPEND CMAKE_C_STANDARD_LINK_DIRECTORIES ${ARGV})
    list(APPEND CMAKE_C_STANDARD_LINK_DIRECTORIES ${ARGV})
endfunction()

function(add_standard_include_directories)
    if(ARGC EQUAL 0)
        message(FATAL_ERROR "no args were passed to add_standard_include_directories")
    endif()

    list(APPEND CMAKE_C_STANDARD_INCLUDE_DIRECTORIES ${ARGV})
    list(APPEND CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${ARGV})
endfunction()

function(set_compiler COMPILER_PATH)
    set(CMAKE_C_COMPILER "${COMPILER_PATH}" PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER "${COMPILER_PATH}" PARENT_SCOPE)
endfunction()

include("${CMAKE_CURRENT_LIST_DIR}/msvc-clang-ninja.toolchain.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/windows-sdk.toolchain.cmake")
