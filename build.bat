@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" || goto :error
set LLVM=C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/Llvm/x64/bin
cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER:FILEPATH="%LLVM%/clang-cl.exe" -DCMAKE_LINKER_TYPE=LLD || goto :error
cmake --build build || goto :error
cmake --install build --prefix C:/Users/Cameron/Code/engine/target || goto :error

:error
exit /b %errorlevel%
