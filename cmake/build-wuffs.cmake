set(SUBMACHINE_INCLUDE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include")

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/vendor/wuffs/release/c/wuffs-unsupported-snapshot.c"
    "${SUBMACHINE_INCLUDE_PATH}/wuffs/wuffs-base.c"
    NO_SOURCE_PERMISSIONS
    COPYONLY
)

add_library(wuffs_base INTERFACE)

include(GNUInstallDirs)
set(WUFFS_BASE_DIRS
    "$<BUILD_INTERFACE:${SUBMACHINE_INCLUDE_PATH}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)
set(WUFFS_BASE_SOURCE_FILES
    "$<BUILD_INTERFACE:${SUBMACHINE_INCLUDE_PATH}/wuffs/wuffs-base.c>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/wuffs/wuffs-base.c>"
)

target_sources(wuffs_base
    INTERFACE
        FILE_SET HEADERS
        BASE_DIRS ${WUFFS_BASE_DIRS}
        FILES ${WUFFS_BASE_SOURCE_FILES}
    INTERFACE ${WUFFS_BASE_SOURCE_FILES}
)

install(FILES
    "${SUBMACHINE_INCLUDE_PATH}/wuffs/wuffs-base.c"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/wuffs"
)
