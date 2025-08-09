@echo off
if not "%2"=="" (
    echo unknown arg %2
    goto error
)
if not "%1"=="" (
    if not "%1"=="--fresh" (
        echo unknown arg %1
        goto error
    )
)

set "SOURCE_DIR=%~dp0"
set "TARGET_DIR=%SOURCE_DIR%\target"

cmake -S . -B build -G Ninja --toolchain "%SOURCE_DIR%\cmake\windows.toolchain.cmake" --install-prefix "%TARGET_DIR%" %1 || goto error
cmake --build build || goto error
cmake --install build --prefix "%TARGET_DIR%" || goto error

exit /b 0

:error
exit /b %errorlevel%
