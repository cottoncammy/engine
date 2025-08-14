#include <SDL3/SDL_error.h>
#include <SDL3/SDL_filesystem.h>
#include <SDL3/SDL_log.h>

#define WUFFS_IMPLEMENTATION
#define WUFFS_CONFIG__MODULES
#define WUFFS_CONFIG__MODULE__BASE
#define WUFFS_CONFIG__MODULE__JSON
#include <wuffs/wuffs-base.c> // NOLINT(bugprone-suspicious-include)

#ifdef SDL_PLATFORM_WIN32
# include <windows.h>
# include <pathcch.h>
#endif
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm_assets.h"

#ifdef SDL_PLATFORM_WIN32
static bool sm_getWideStr(const char *narrow, size_t dstlen, wchar_t *dst) {
    size_t converted = 0;
    if(mbstowcs_s(&converted, dst, dstlen / sizeof(wchar_t), narrow, strlen(narrow)) != 0) {
        goto err;
    }
    // make sure we converted the number of chars in the narrow string plus a null terminator
    if(converted != strlen(narrow)+1) {
        goto err;
    }
    assert(dst[converted-1] == '\0');
    return true;

    err:
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert narrow character string %s to wide character string (%s:%s)", narrow, __FILE_NAME__, __FUNCTION__);
        return false;
}

static bool sm_getNarrowStr(const wchar_t *wide, size_t dstlen, char *dst) {
    size_t converted = 0;
    if(wcstombs_s(&converted, dst, dstlen, wide, dstlen-1) != 0) {
        goto err;
    }
    // make sure we converted the number of chars in the wide string plus a null terminator
    if(converted != wcslen(wide)+1) {
        goto err;
    }

    assert(dst[converted-1] == '\0');
    return true;

    err:
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert wide character string to narrow character string %s (%s:%s)", dst, __FILE_NAME__, __FUNCTION__);
        return false;
}
#endif

static bool sm_appendPath(size_t *wc_dstlen, void *wc_dst, size_t nc_dstlen, char *nc_dst, const char *append) {
#ifdef SDL_PLATFORM_WIN32
    if(!sm_getWideStr(nc_dst, *wc_dstlen, (wchar_t*)wc_dst)) {
        return false;
    }
    wchar_t wc_append[MAX_PATH] = { 0 };
    if(!sm_getWideStr(append, sizeof(wc_append), wc_append)) {
        return false;
    }

    // append the path segment and store result back into the narrow string
    const HRESULT hresult = PathCchAppend((wchar_t*)wc_dst, *wc_dstlen / sizeof(wchar_t), wc_append);
    if(FAILED(hresult)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to append path %s to %s: error code %ld (%s:%s)", append, nc_dst, HRESULT_CODE(hresult), __FILE_NAME__, __FUNCTION__);
        return false;
    }
    if(!sm_getNarrowStr((wchar_t*)wc_dst, nc_dstlen, nc_dst)) {
        return false;
    }

    // make sure the string length isn't longer than MAX_PATH
    const size_t actual_len = strlen(nc_dst);
    assert(actual_len > 0 && actual_len <= MAX_PATH);
    assert(nc_dst[actual_len] == '\0');

#endif
    return true;
}

static bool sm_getFileExt(const void *fpath, const void **dst) {
#ifdef SDL_PLATFORM_WIN32
    const wchar_t *wc_fpath = (wchar_t*)fpath;
    const HRESULT hresult = PathCchFindExtension(wc_fpath, wcslen(wc_fpath)+1, (const wchar_t**)dst);
    if(FAILED(hresult) || (dst && *(wchar_t*)dst == '\0')) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to extract file extension: error code %ld (%s:%s)", HRESULT_CODE(hresult), __FILE_NAME__, __FUNCTION__);
        return false;
    }

#endif
    return true;
}

static bool sm_getAssetsPath(size_t dstlen, char *dst) {
    const char *bin = SDL_GetBasePath();
    // strcpy_s handles buffer overflows for us
    if(strcpy_s(dst, dstlen / 2, bin) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy string %s to %s (%s:%s)", bin, dst, __FILE_NAME__, __FUNCTION__);
        return false;
    }

#if SDL_PLATFORM_WIN32
    wchar_t wc_dst[MAX_PATH] = { 0 };
    size_t wc_dstlen = sizeof(wc_dst);
    const char *append = "assets";
    if(!sm_appendPath(&wc_dstlen, (void*)wc_dst, dstlen, dst, append)) {
        return false;
    }

#endif
    return true;
}

static struct sm_assets_state {
    sm_state *appstate;
    const char *assets_path;
} sm_assets_state;

static SDL_EnumerationResult SDLCALL sm_walkAssetsDir(void *userdata, const char *dirname, const char *fname) {
    struct sm_assets_state *state = (struct sm_assets_state*)userdata;
#ifdef SDL_PLATFORM_WIN32
    // copy the assets_path to a new buffer
    char nc_fpath[MAX_PATH*2] = { 0 };
    if(strcpy_s(nc_fpath, sizeof(nc_fpath) / 2, state->assets_path) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy string %s to %s (%s:%s)", state->assets_path, nc_fpath, __FILE_NAME__, __FUNCTION__);
        return SDL_ENUM_FAILURE;
    }

    // append the filename to the buffer
    wchar_t wc_fpath[MAX_PATH] = { 0 };
    size_t wc_fpath_len = sizeof(wc_fpath);
    if(!sm_appendPath(&wc_fpath_len, wc_fpath, sizeof(nc_fpath), nc_fpath, fname)) {
        return SDL_ENUM_FAILURE;
    }

    // ensure the item is a file
    SDL_PathInfo info = { 0 };
    if(!SDL_GetPathInfo(nc_fpath, &info)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get SDL path info for %s: %s (%s:%s)", nc_fpath, SDL_GetError(), __FILE_NAME__, __FUNCTION__);
        return SDL_ENUM_FAILURE;
    }
    if(info.type != SDL_PATHTYPE_FILE) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Found unexpected item in assets dir: %s", fname);
        return SDL_ENUM_FAILURE;
    }

    // check the file type
    wchar_t ext[MAX_PATH] = { 0 };
    if (!sm_getFileExt((void*)wc_fpath, (const void**)&ext)) {
        return SDL_ENUM_FAILURE;
    }

#endif
    return SDL_ENUM_CONTINUE;
}

bool sm_initAssets(sm_state* state) {
#ifdef SDL_PLATFORM_WIN32
    // allocate 2 bytes for each allowed character in the path
    // so we can safely store the wide string result in the narrow string
    char assets_path[MAX_PATH*2] = { 0 };
#endif
    if(!sm_getAssetsPath(sizeof(assets_path), assets_path)) {
        return false;
    }
    // ensure the asset path points to a dir
    SDL_PathInfo info = { 0 };
    if(!SDL_GetPathInfo(assets_path, &info)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get SDL path info for %s: %s (%s:%s)", assets_path, SDL_GetError(), __FILE_NAME__, __FUNCTION__);
        return false;
    }
    if(info.type != SDL_PATHTYPE_DIRECTORY) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Assets path (%s) doesn't point to a dir", assets_path);
        return false;
    }

    // walk the dir
    struct sm_assets_state assets_state = {
        .appstate = state,
        .assets_path = assets_path,
    };
    if(!SDL_EnumerateDirectory(assets_path, sm_walkAssetsDir, &assets_state)) {
        return false;
    }

    return true;
}

void sm_deinitAssets(sm_state* state) {

}
