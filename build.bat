@echo off
set MSVC=%ProgramFiles(x86)%/Microsoft Visual Studio/2022/BuildTools
cmake -S . -B build -G Ninja -DCMAKE_PROGRAM_PATH="%MSVC%/Common7/IDE/CommonExtensions/Microsoft/CMake/Ninja" -DCMAKE_C_COMPILER:FILEPATH="%MSVC%/VC/Tools/Llvm/x64/bin/clang-cl.exe" -DCMAKE_LINKER_TYPE=LLD || goto :error
cmake --build build || goto :error
cmake --install build --prefix "%UserProfile%/Code/engine/target" || goto :error

:error
exit /b %errorlevel%
