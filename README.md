# engine

`engine` is a ~game engine~ rendering window written in C11.

## Third-Party Software

The following free and open source software are used directly:

* [CMake](https://github.com/Kitware/CMake)
* [Golang](https://github.com/golang/go)
* [LLVM](https://github.com/llvm/llvm-project)
* [Ninja](https://github.com/ninja-build/ninja)
* [SDL3](https://github.com/libsdl-org/SDL)
* [SDL3_shadercross](https://github.com/libsdl-org/SDL_shadercross)
* [vswhere](https://github.com/microsoft/vswhere)
* [wuffs](https://github.com/google/wuffs)
* [xwin](https://github.com/Jake-Shadle/xwin)

## Development Environment

To build and run `engine`, you must be on Windows x64. You need the following binaries downloaded and installed in your path:

* CMake ([download link](https://cmake.org/download))
* Golang ([download link](https://go.dev/doc/install))

Additionally, you need the build tools for Visual Studio 2022 ([download link](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)). You will need the "Desktop development with C++" workload with the following additional components:

* MSVC - VS 2022 C++ x64/x86 build tools (latest)
* Windows 11 SDK (latest)
* C++ CMake tools
* C++ Clang tools

## Installation

`engine` must be built from source using CMake. Currently, bulding `engine` is only supported on Windows x64 for Windows x64.

Checkout using `git clone --recurse-submodules`, then run `./build.bat` to build and install the binary.
