function(xwin_splat xwin_exe)
    execute_process(COMMAND
        "${xwin_exe}" --accept-license --arch x86_64 --cache-dir .xwin-cache --manifest-version 17 splat --output "${WINDOWS_X86_X64_SYSROOT}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()


if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
    message(FATAL_ERROR "cross compiling to Windows x86_64 is only supported on Linux")
endif()

option(WINDOWS_X86_X64_SYSROOT "Path to the Windows x86_64 sysroot on the host system" "/xwin/msvc17")
option(DOWNLOAD_WINDOWS_X86_X64_SYSROOT "Download the Windows x86_64 sysroot using xwin if the given sysroot path at WINDOWS_X86_X64_SYSROOT is not found on the host system" OFF)
option(KEEP_XWIN_BIN "Whether to install the vendored xwin binary to CMAKE_STAGING_PREFIX if it's not found on the host system when the given Windows x86_64 sysroot path also isn't found" OFF)

if(KEEP_XWIN_BIN AND NOT DEFINED CMAKE_STAGING_PREFIX)
    message(FATAL_ERROR "CMAKE_STAGING_PREFIX should be defined if KEEP_XWIN_BIN is ON")
endif()

set(WINDOWS_X86_X64_FIND_ROOT_PATH "${CMAKE_INSTALL_PREFIX}")

# assume that the path has the CRT and Windows SDK if it exists
if(NOT EXISTS WINDOWS_X86_X64_SYSROOT AND DOWNLOAD_WINDOWS_X86_X64_SYSROOT)
    find_program(XWIN_BIN
        xwin
        OPTIONAL
        NO_CMAKE_ENVIRONMENT_PATH
        NO_SYSTEM_ENVIRONMENT_PATH
    )

    if(DEFINED XWIN_BIN)
        xwin_splat("${XWIN_BIN}")
    else()
        # xwin doesn't distribute a binary linked with glibc so it must be built from source which means cargo is needed lol
        find_program(CARGO_BIN
            cargo
            REQUIRED
            NO_CMAKE_ENVIRONMENT_PATH
            NO_SYSTEM_ENVIRONMENT_PATH
        )

        if(KEEP_XWIN_BIN)
            set(CARGO_COMMAND install xwin --root "${CMAKE_STAGING_PREFIX}" --path vendor/xwin)
            set(XWIN_BIN "${CMAKE_STAGING_PREFIX}/xwin")
        else()
            set(CARGO_COMMAND build --manifest-path vendor/xwin --release)
            set(XWIN_BIN "${CMAKE_CURRENT_BINARY_DIR}/vendor/xwin")
        endif()
        unset(KEEP_XWIN)

        execute_process(COMMAND
            "${CARGO_BIN}" ${CARGO_COMMAND} --bin xwin --features native-tls --target x86_64-unknown-linux-gnu --target-dir "${CMAKE_CURRENT_BINARY_DIR}/vendor/xwin" --frozen
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            COMMAND_ERROR_IS_FATAL ANY
        )

        unset(CARGO_COMMAND)
        xwin_splat("${XWIN_BIN}")
        unset(XWIN_BIN)
    endif()
elseif(NOT EXISTS WINDOWS_X86_X64_SYSROOT)
    message(FATAL_ERROR "the given path to the Windows x86_64 sysroot at WINDOWS_X86_X64_SYSROOT was not found on the host system and DOWNLOAD_WINDOWS_X86_X64_SYSROOT is OFF")
endif()

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(triple x86_64-pc-windows-msvc)

set(CMAKE_SYSROOT "${WINDOWS_X86_X64_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${WINDOWS_X86_X64_FIND_ROOT_PATH}")

unset(WINDOWS_X86_X64_SYSROOT)
unset(WINDOWS_X86_X64_FIND_ROOT_PATH)

set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_ASM_COMPILER_TARGET ${triple})
set(CMAKE_LINKER llvm-lld)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
