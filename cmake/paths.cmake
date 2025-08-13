macro(check_path PATH_VAR)
    if(NOT EXISTS "${PATH_VAR}")
        message(FATAL_ERROR "path ${PATH_VAR} doesn't exist")
    endif()
endmacro()

function(_check_paths)
    foreach(PATH_VAR IN LISTS ${ARGN})
        check_path("${PATH_VAR}")
    endforeach()
endfunction()

macro(set_and_check_path OUT_VAR PATH_VAR)
    check_path("${PATH_VAR}")
    set(${OUT_VAR} "${PATH_VAR}")
endmacro()

macro(cache_and_check_path OUT_VAR PATH_VAR)
    check_path("${PATH_VAR}")
    set(${OUT_VAR} "${PATH_VAR}" CACHE PATH "")
endmacro()

macro(set_and_append_paths OUT_VAR)
    _check_paths(${ARGN})
    list(APPEND ${OUT_VAR} ${ARGN})
endmacro()

function(get_relative_path PATH_VAR BASE_DIR OUT_VAR)
    cmake_path(RELATIVE_PATH
        PATH_VAR
        BASE_DIRECTORY "${BASE_DIR}"
        OUTPUT_VARIABLE OUT_VAR
    )
    cmake_path(NATIVE_PATH OUT_VAR OUT_VAR)
endfunction()
