set(WUFFS_INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/vendor/wuffs")

if(CMAKE_CROSSCOMPILING)
    include(GNUInstallDirs)
    set(WUFFS_BIN_PATH "${CMAKE_STAGING_PREFIX}/${CMAKE_INSTALL_BINDIR}")
else()
    set(WUFFS_BIN_PATH "${WUFFS_INSTALL_PATH}")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs/release/c/wuffs-v0.3.c"
    "${WUFFS_INSTALL_PATH}/wuffs-base.c"
    NO_SOURCE_PERMISSIONS
    COPYONLY
)

add_library(wuffs_base INTERFACE)
set(WUFFS_BASE_DIRS
    "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}>"
    $<INSTALL_INTERFACE:include/wuffs>
)

target_sources(wuffs_base
    INTERFACE
        FILE_SET wuffs_base_header
        TYPE HEADERS
        BASE_DIRS ${WUFFS_BASE_DIRS}
            "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}>"
            $<INSTALL_INTERFACE:include/wuffs>
        FILES
            "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-base.c>"
            $<INSTALL_INTERFACE:include/wuffs/wuffs-base.c>
    INTERFACE
        "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-base.c>"
        $<INSTALL_INTERFACE:include/wuffs/wuffs-base.c>
)

find_program(GO_BIN go REQUIRED)
add_custom_command(COMMAND
    "${GO_BIN}" build -o "${WUFFS_BIN_PATH}" ./cmd/wuffs-c
    OUTPUT "${WUFFS_BIN_PATH}/wuffs-c.exe"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs"
    COMMENT "TODO"
    VERBATIM
)

set(WUFFS_FOO_SRC_FILES
    src/foo.wuffs
)
list(TRANSFORM WUFFS_FOO_SRC_FILES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")
add_custom_command(COMMAND
    wuffs-c gen -package_name foo ${WUFFS_FOO_SRC_FILES} > "${WUFFS_INSTALL_PATH}/wuffs-foo.c"
    DEPENDS ${WUFFS_FOO_SRC_FILES} "${WUFFS_INSTALL_PATH}/wuffs-base.c" "${WUFFS_BIN_PATH}/wuffs-c.exe"
    OUTPUT "${WUFFS_INSTALL_PATH}/wuffs-foo.c"
    WORKING_DIRECTORY "${WUFFS_BIN_PATH}"
    COMMENT "TODO"
    VERBATIM
    COMMAND_EXPAND_LISTS
)

add_library(wuffs_foo INTERFACE)
get_property(foo TARGET wuffs_base PROPERTY FOO)
set_property(TARGET wuffs_foo PROPERTY FOO "")

target_sources(wuffs_foo
    INTERFACE
        FILE_SET wuffs_foo_headers
        TYPE HEADERS
        BASE_DIRS
            "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}>"
            $<INSTALL_INTERFACE:include/wuffs>
        FILES
            "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-base.c>"
            $<INSTALL_INTERFACE:include/wuffs/wuffs-base.c>
            "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-foo.c>"
            $<INSTALL_INTERFACE:include/wuffs/wuffs-foo.c>
    INTERFACE
        "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-base.c>"
        $<INSTALL_INTERFACE:include/wuffs/wuffs-base.c>
        "$<BUILD_INTERFACE:${WUFFS_INSTALL_PATH}/wuffs-foo.c>"
        $<INSTALL_INTERFACE:include/wuffs/wuffs-foo.c>
)
