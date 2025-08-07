include_guard(GLOBAL)

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR NOT CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64")
    message(FATAL_ERROR "this toolchain file is only supported on 64-bit x86 Windows host systems")
endif()

set(VSWHERE_INSTALL_PATH "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer")
if(NOT EXISTS "${VSWHERE_INSTALL_PATH}")
    set(VSWHERE_VERSION 3.1.7)
    set(VSWHERE_URL https://github.com/microsoft/vswhere/releases/download/${VSWHERE_VERSION}/vswhere.exe)
    set(VSWHERE_URL_HASH SHA256=c54f3b7c9164ea9a0db8641e81ecdda80c2664ef5a47c4191406f848cc07c662)
    set(VSWHERE_INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/vendor/vswhere")

    file(DOWNLOAD ${VSWHERE_URL}
        "${VSWHERE_INSTALL_PATH}/vswhere.exe"
        STATUS VSWHERE_DOWNLOAD_STATUS
        EXPECTED_HASH ${VSWHERE_URL_HASH}
    )

    list(GET VSWHERE_DOWNLOAD_STATUS 0 RETURN_CODE)
    if(NOT RETURN_CODE EQUAL 0)
        list(GET VSWHERE_DOWNLOAD_STATUS 1 RETURN_MESSAGE)
        message(FATAL_ERROR "vswhere wasn't found on the system and couldn't be downloaded: ${RETURN_MESSAGE}")
    endif()

    unset(VSWHERE_URL_HASH)
    unset(VSWHERE_URL)
    unset(VSWHERE_VERSION)
endif()

set(VSWHERE_REQUIRES
    Microsoft.VisualStudio.Workload.MSBuildTools
    Microsoft.VisualStudio.Workload.VCTools
    Microsoft.VisualStudio.Component.VC.CMake.Project
    Microsoft.VisualStudio.Component.VC.Tools.x86.x64
    Microsoft.VisualStudio.Component.Windows11SDK.26100
    Microsoft.VisualStudio.Component.VC.Llvm.Clang
    Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset
    Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Llvm.Clang
)

execute_process(COMMAND
    "${VSWHERE_INSTALL_PATH}/vswhere" -products Microsoft.VisualStudio.Product.BuildTools
        -latest -version 17 -requires ${VSWHERE_REQUIRES} -property installationPath
    WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
    OUTPUT_VARIABLE VS17_INSTALL_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
unset(VSWHERE_REQUIRES)
unset(VSWHERE_INSTALL_PATH)

if(NOT VS17_INSTALL_PATH)
    message(FATAL_ERROR "vswhere couldn't find an installation of Visual Studio 17 Build Tools with the required workloads and components")
endif()

cmake_path(NORMAL_PATH VS17_INSTALL_PATH)
list(APPEND CMAKE_PROGRAM_PATH "${VS17_INSTALL_PATH}/Common7/IDE/CommonExtensions/Microsoft/CMake/Ninja")

file(READ "${VS17_INSTALL_PATH}/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt" VS17_MSVC_VERSION LIMIT_COUNT 1)
if(NOT VS17_MSVC_VERSION)
    message(FATAL_ERROR "the installed version of MSVC couldn't be determined")
endif()
string(STRIP ${VS17_MSVC_VERSION} VS17_MSVC_VERSION)

set(VS17_MSVC_INSTALL_PATH "${VS17_INSTALL_PATH}/VC/Tools/MSVC/${VS17_MSVC_VERSION}")
add_standard_link_directories("${VS17_MSVC_INSTALL_PATH}/lib/x64")
add_standard_include_directories("${VS17_MSVC_INSTALL_PATH}/include")

set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreaded$<$<CONFIG:Debug>:Debug>)

set(VS17_LLVM_INSTALL_PATH "${VS17_INSTALL_PATH}/VC/Tools/Llvm/x64/bin")
set_compiler("${VS17_LLVM_INSTALL_PATH}/clang-cl.exe")
set(CMAKE_LINKER_TYPE LLD)
set(CMAKE_RC_COMPILER "${VS17_LLVM_INSTALL_PATH}/llvm-rc.exe")
