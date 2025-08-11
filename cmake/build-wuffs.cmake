set(WUFFS_INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/vendor/wuffs")

if(CMAKE_CROSSCOMPILING)
    include(GNUInstallDirs)
    set(WUFFS_BIN_PATH "${CMAKE_STAGING_PREFIX}/${CMAKE_INSTALL_BINDIR}")
else()
    set(WUFFS_BIN_PATH "${WUFFS_INSTALL_PATH}")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs/release/c/wuffs-unsupported-snapshot.c"
    "${WUFFS_INSTALL_PATH}/wuffs-base.c"
    NO_SOURCE_PERMISSIONS
    COPYONLY
)

add_library(wuffs_base INTERFACE)
set(WUFFS_BASE_DIRS
    "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}>"
    $<INSTALL_INTERFACE:include/wuffs>
)
set(WUFFS_BASE_SOURCE_FILES
    "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-base.c>"
    $<INSTALL_INTERFACE:include/wuffs/wuffs-base.c>
)

target_sources(wuffs_base
    INTERFACE
        FILE_SET wuffs_base_header
        TYPE HEADERS
        BASE_DIRS ${WUFFS_BASE_DIRS}
        FILES ${WUFFS_BASE_SOURCE_FILES}
    INTERFACE ${WUFFS_BASE_SOURCE_FILES}
)

find_program(GO_BIN go REQUIRED)
add_custom_command(COMMAND
    "${GO_BIN}" build -o "${WUFFS_BIN_PATH}" ./cmd/wuffs-c
    OUTPUT "${WUFFS_BIN_PATH}/wuffs-c.exe"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs"
    COMMENT "Building C executable wuffs-c${CMAKE_EXECUTABLE_SUFFIX} with Go"
    VERBATIM
)

set(WUFFS_SM_IN_SOURCE_FILES
    src/foo.wuffs
)
list(TRANSFORM WUFFS_SM_IN_SOURCE_FILES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")
add_custom_command(COMMAND
    wuffs-c gen -package_name submachine ${WUFFS_SM_IN_SOURCE_FILES} > "${WUFFS_INSTALL_PATH}/wuffs-submachine.c"
    DEPENDS ${WUFFS_SM_IN_SOURCE_FILES} "${WUFFS_INSTALL_PATH}/wuffs-base.c" "${WUFFS_BIN_PATH}/wuffs-c.exe"
    OUTPUT "${WUFFS_INSTALL_PATH}/wuffs-submachine.c"
    WORKING_DIRECTORY "${WUFFS_BIN_PATH}"
    COMMENT "Generating wuffs-submachine.c from src\\foo.wuffs"
    VERBATIM
    COMMAND_EXPAND_LISTS
)

add_library(wuffs_submachine INTERFACE)
set(WUFFS_SM_OUT_SOURCE_FILES
    "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-submachine.c>"
    $<INSTALL_INTERFACE:include/wuffs/wuffs-submachine.c>
)
target_sources(wuffs_submachine
    INTERFACE
        FILE_SET wuffs_submachine_headers
        TYPE HEADERS
        BASE_DIRS ${WUFFS_BASE_DIRS}
        FILES
            ${WUFFS_BASE_SOURCE_FILES}
            ${WUFFS_SM_OUT_SOURCE_FILES}
    INTERFACE
        ${WUFFS_BASE_SOURCE_FILES}
        ${WUFFS_SM_OUT_SOURCE_FILES}
)
