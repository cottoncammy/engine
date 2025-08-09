macro(xwin_splat XWIN_BIN)
    execute_process(COMMAND
        "${XWIN_BIN}" --accept-license --arch x86_64 --cache-dir ./.xwin-cache --manifest-version 17 splat --output "${WINDOWS_X64_SYSROOT}"
        WORKING_DIRECTORY "${CMAKE_STAGING_PREFIX}"
        COMMAND_ERROR_IS_FATAL ANY
    )
endmacro()

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "cross compiling to Windows x64 is only supported on Linux")
endif()

option(WINDOWS_X64_SYSROOT "Path to the Windows x64 sysroot on the host" "/xwin/msvc17")
option(DOWNLOAD_WINDOWS_X64_SYSROOT "Download the Windows x64 sysroot using xwin if WINDOWS_X64_SYSROOT isn't found on the host (requires cargo)" OFF)

if(NOT CMAKE_STAGING_PREFIX OR NOT WINDOWS_X64_SYSROOT)
    message(FATAL_ERROR "CMAKE_STAGING_PREFIX and WINDOWS_X64_SYSROOT are required")
endif()

set(WINDOWS_X64_FIND_ROOT_PATH "${CMAKE_INSTALL_PREFIX}")

# assume that the path has the CRT and Windows SDK if it exists
if(NOT EXISTS WINDOWS_X64_SYSROOT AND DOWNLOAD_WINDOWS_X64_SYSROOT)
    find_program(XWIN_BIN xwin OPTIONAL)
    if(XWIN_BIN)
        xwin_splat("${XWIN_BIN}")
    else()
        # xwin doesn't distribute a binary linked with glibc so it must be built from source which means cargo is needed lol
        find_program(CARGO_BIN cargo REQUIRED)
        set(XWIN_INSTALL_PATH "${CMAKE_STAGING_PREFIX}/vendor/xwin")

        execute_process(COMMAND
            "${CARGO_BIN}" build --manifest-path vendor/xwin --release --bin xwin --features native-tls --target x86_64-unknown-linux-gnu --target-dir "${XWIN_INSTALL_PATH}" --frozen
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            COMMAND_ERROR_IS_FATAL ANY
        )

        xwin_splat("${XWIN_INSTALL_PATH}")
    endif()
elseif(NOT EXISTS WINDOWS_X64_SYSROOT)
    message(FATAL_ERROR "the Windows x64 sysroot (${WINDOWS_X64_SYSROOT}) doesn't exist on the host and DOWNLOAD_WINDOWS_X64_SYSROOT is OFF")
endif()

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(triple x86_64-pc-windows-msvc)

set(CMAKE_SYSROOT "${WINDOWS_X64_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${WINDOWS_X64_FIND_ROOT_PATH}")

set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_ASM_COMPILER_TARGET ${triple})
set(CMAKE_LINKER llvm-lld)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
