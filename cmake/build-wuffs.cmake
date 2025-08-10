include(GNUInstallDirs)
set(WUFFS_INCLUDE_PATH "${CMAKE_INSTALL_FULL_INCLUDEDIR}/wuffs")

if(CMAKE_CROSSCOMPILING)
    set(WUFFS_BIN_PATH "${CMAKE_STAGING_PREFIX}/${CMAKE_INSTALL_BINDIR}")
else()
    set(WUFFS_BIN_PATH "${CMAKE_CURRENT_BINARY_DIR}/vendor/wuffs")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs/release/c/wuffs-v0.3.c"
    "${WUFFS_INCLUDE_PATH}/wuffs-base.c"
    NO_SOURCE_PERMISSIONS
    COPYONLY
)

add_library(wuffs_base INTERFACE)
target_sources(wuffs_base
    INTERFACE
        FILE_SET wuffs_base_header
        TYPE HEADERS
        BASE_DIRS "${WUFFS_INCLUDE_PATH}"
        FILES
            "${WUFFS_INCLUDE_PATH}/wuffs-base.c"
    INTERFACE
        "${WUFFS_INCLUDE_PATH}/wuffs-base.c"
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
    wuffs-c gen -package_name foo ${WUFFS_FOO_SRC_FILES} > "${WUFFS_INCLUDE_PATH}/wuffs-foo.c"
    DEPENDS "${WUFFS_INCLUDE_PATH}/wuffs-base.c" "${WUFFS_BIN_PATH}/wuffs-c.exe"
    OUTPUT "${WUFFS_INCLUDE_PATH}/wuffs-foo.c"
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
        BASE_DIRS "${WUFFS_INCLUDE_PATH}"
        FILES
            "${WUFFS_INCLUDE_PATH}/wuffs-base.c"
            "${WUFFS_INCLUDE_PATH}/wuffs-foo.c"
    INTERFACE
        "${WUFFS_INCLUDE_PATH}/wuffs-base.c"
        "${WUFFS_INCLUDE_PATH}/wuffs-foo.c"
)
