@echo off
set SOURCE_DIR=%~dp0

cmake -S . -B build -G Ninja --toolchain "%SOURCE_DIR%/cmake/windows.toolchain.cmake"^
 || goto error

cmake --build build || goto error
cmake --install build --prefix "%SOURCE_DIR%/target" || goto error

exit /b 0

:error
exit /b %errorlevel%
