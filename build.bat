@echo off

:parse_args
if "%1"=="" goto build

if /I "%1"=="--dbg" (
  set "cmake_config=--config Debug"
) else (
  if /I "%1"=="--rel" (
    set "cmake_config=--config Release"
  ) else (
    if /I "%1"=="--asan" (
      set "cmake_config=--config ReleaseASAN"
    ) else (
      if /I "%1"=="--fresh" (
        set "cmake_fresh=--fresh"
      ) else (
        echo unknown arg: %1
        goto error
      )
    )
  )
)

shift
goto parse_args

:build
set "src_dir=%~dp0"
set "target_dir=%src_dir%\target"

cmake -S . -B build -G "Ninja Multi-Config" --toolchain "%src_dir%\cmake\windows.toolchain.cmake" --install-prefix "%target_dir%" %cmake_fresh% || goto error
cmake --build build %cmake_config% || goto error
cmake --install build --prefix "%target_dir%" || goto error

exit /b 0

:error
exit /b %errorlevel%
