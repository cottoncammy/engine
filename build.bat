@echo off
if not "%2"=="" (
    echo unknown arg
    goto error
)
if not "%1"=="" (
    if not "%1"=="--fresh" (
        echo unknown arg
        goto error
    )
)

set "SOURCE_DIR=%~dp0"

cmake -S . -B build -G Ninja --toolchain "%SOURCE_DIR%/cmake/windows.toolchain.cmake" %1^
 || goto error
cmake --build build || goto error
cmake --install build --prefix "%SOURCE_DIR%/target" || goto error

exit /b 0

:error
exit /b %errorlevel%
