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
# define SM_MAX_PATH MAX_PATH
#endif
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#define __STDC_WANT_LIB_EXT1__ 1
#include <string.h>

#include "sm_assets.h"

#ifdef SDL_PLATFORM_WIN32
static bool sm_getWideStr(size_t nc_len, const char *nc, size_t dstlen, wchar_t *dst) {
    size_t converted = 0;
    const size_t actual_len = strnlen_s(nc, nc_len);
    assert(nc[actual_len] == '\0'); // make sure we found the actual length
    if(mbstowcs_s(&converted, dst, dstlen / sizeof(wchar_t), nc, actual_len) != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(_strerror_s(errmsg, sizeof(errmsg), NULL) != 0);

        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert narrow character string %s to wide character string: %s (%s:%s)", nc, errmsg, __FILE_NAME__, __FUNCTION__);
        return false;
    }

    // make sure we converted the number of chars in the narrow string plus a null terminator
    if(converted != actual_len+1) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert narrow character string %s to wide character string (%s:%s)", nc, __FILE_NAME__, __FUNCTION__);
        return false;
    }

    assert(dst[converted-1] == '\0');
    return true;
}

static bool sm_getNarrowStr(size_t wc_len, const wchar_t *wc, size_t dstlen, char *dst) {
    size_t converted = 0;
    if(wcstombs_s(&converted, dst, dstlen, wc, dstlen-1) != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(_strerror_s(errmsg, sizeof(errmsg), NULL) != 0);

        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert wide character string to narrow character string %s: %s (%s:%s)", dst, errmsg, __FILE_NAME__, __FUNCTION__);
        return false;
    }

    // make sure we converted the number of chars in the wide string plus a null terminator
    const size_t actual_len = wcsnlen_s(wc, wc_len);
    assert(wc[actual_len] == '\0'); // make sure we found the actual length
    if(converted != actual_len+1) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert wide character string to narrow character string %s (%s:%s)", dst, __FILE_NAME__, __FUNCTION__);
        return false;
    }

    assert(dst[converted-1] == '\0');
    return true;
}

static bool sm_getNarrowStrPath(size_t wc_len, const wchar_t *wc, size_t dstlen, char *dst) {
    bool result = sm_getNarrowStr(wc_len, wc, dstlen, dst);
    const size_t actual_len = strnlen_s(dst, dstlen);
    assert(dst[actual_len] == '\0');
    assert(actual_len > 0 && actual_len <= SM_MAX_PATH);
    return result;
}
#endif

static bool sm_appendPath(size_t *wc_dstlen, wchar_t *wc_dst, size_t nc_dstlen, char *nc_dst, size_t append_len, const char *append) {
#ifdef SDL_PLATFORM_WIN32
    if(!sm_getWideStr(nc_dstlen, nc_dst, *wc_dstlen, wc_dst)) {
        return false;
    }
    wchar_t wc_append[SM_MAX_PATH] = { 0 };
    if(!sm_getWideStr(append_len, append, sizeof(wc_append), wc_append)) {
        return false;
    }

    // append the path segment and store the result back into the narrow string
    const HRESULT hresult = PathCchAppend(wc_dst, *wc_dstlen / sizeof(wchar_t), wc_append);
    if(FAILED(hresult)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to append path %s to %s: error code %ld (%s:%s)", append, nc_dst, HRESULT_CODE(hresult), __FILE_NAME__, __FUNCTION__);
        return false;
    }
    return sm_getNarrowStrPath(*wc_dstlen, wc_dst, nc_dstlen, nc_dst);
#endif
}

static bool sm_getFileExt(size_t fpath_len, const void *fpath, size_t dstlen, char* dst) {
#ifdef SDL_PLATFORM_WIN32
    wchar_t *wc_fpath = (wchar_t*)fpath;
    const size_t wc_len = wcsnlen_s(wc_fpath, fpath_len);
    assert(wc_fpath[wc_len] == '\0'); // make sure we found the actual length
    wchar_t wc_dst[SM_MAX_PATH] = { 0 };
    const wchar_t **wc_dstptr = (const wchar_t**)&wc_dst;

    const HRESULT hresult = PathCchFindExtension(wc_fpath, wc_len+1, wc_dstptr);
    if(FAILED(hresult) || (wc_dstptr && (**wc_dstptr == '\0'))) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get file extension: error code %ld (%s:%s)", HRESULT_CODE(hresult), __FILE_NAME__, __FUNCTION__);
        return false;
    }

    return sm_getNarrowStrPath(sizeof(*wc_dstptr), *wc_dstptr, dstlen, dst);
#endif
}

static bool sm_getFileStem(size_t fname_len, const char *fname, size_t dstlen, char *dst) {
#ifdef SDL_PLATFORM_WIN32
    wchar_t wc_fname[SM_MAX_PATH] = { 0 };
    if(!sm_getWideStr(fname_len, fname, sizeof(wc_fname), wc_fname)) {
        return false;
    }

    const HRESULT hresult = PathCchRemoveExtension(wc_fname, sizeof(wc_fname) / sizeof(wchar_t));
    if(FAILED(hresult)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get file stem from %s: error code %ld (%s:%s)", fname, HRESULT_CODE(hresult), __FILE_NAME__, __FUNCTION__);
        return false;
    }

    return sm_getNarrowStrPath(sizeof(wc_fname), wc_fname, dstlen, dst);
#endif
}

static bool sm_getAssetsPath(size_t dstlen, char *dst) {
    const char *bin = SDL_GetBasePath();
    const errno_t errnum = strcpy_s(dst, dstlen / 2, bin);
    if(errnum != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errnum) != 0);

        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy string %s to %s: %s (%s:%s)", bin, dst, errmsg, __FILE_NAME__, __FUNCTION__);
        return false;
    }

#if SDL_PLATFORM_WIN32
    wchar_t wc_dst[SM_MAX_PATH] = { 0 };
    size_t wc_dstlen = sizeof(wc_dst);
    const char *append = "assets";
    // we explicitly want sizeof rather than strlen
    // NOLINTNEXTLINE(bugprone-sizeof-expression)
    if(!sm_appendPath(&wc_dstlen, (void*)wc_dst, dstlen, dst, sizeof(append), append)) {
        return false;
    }

#endif
    return true;
}

static struct sm_assets_state {
    sm_state *appstate;
    const char *assets_path;
} sm_assets_state;

static bool sm_readFile(struct sm_assets_state *state, const char *fname) {
    FILE *file = NULL;
    const errno_t errnum = fopen_s(&file, fname, "rb");
    if (errnum != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errnum) != 0);
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to open file %s: %s", fname, errmsg);
        return false;
    }

    char buf[SM_MAX_FILE] = { 0 };
#ifdef SDL_PLATFORM_WIN32
    // use _fread_nolock because this call stack is single-threaded for now

    // a widening conversion from a positive int to size_t won't matter here
    // NOLINTNEXTLINE(bugprone-implicit-widening-of-multiplication-result)
    const size_t bytes_read = _fread_nolock_s(buf, sizeof(buf), sizeof(char), SM_MAX_FILE, file);
#endif
    if (ferror(file) != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errno) != 0);
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to read file %s: %s", fname, errmsg);
        return false;
    }
    if (bytes_read == 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "File %s was empty", fname);
        return false;
    }

    if (fclose(file) != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errno) != 0);
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to close file %s: %s", fname, errmsg);
        return false;
    }

    return true;
}

static SDL_EnumerationResult SDLCALL sm_walkAssetsDir(void *userdata, const char *dirname, const char *fname) {
    struct sm_assets_state *state = (struct sm_assets_state*)userdata;
    // copy the assets_path to a new buffer
    char fpath[SM_MAX_PATH*2] = { 0 };
    errno_t errnum = strcpy_s(fpath, sizeof(fpath) / 2, state->assets_path);
    if(strcpy_s(fpath, sizeof(fpath) / 2, state->assets_path) != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errnum) != 0);

        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy string %s to %s: %s (%s:%s)", state->assets_path, fpath, errmsg, __FILE_NAME__, __FUNCTION__);
        return SDL_ENUM_FAILURE;
    }

#ifdef SDL_PLATFORM_WIN32
    // append the filename to the new buffer
    wchar_t wc_fpath[SM_MAX_PATH] = { 0 };
    size_t wc_fpath_len = sizeof(wc_fpath);
    const size_t fname_len = strnlen_s(fname, SM_MAX_PATH);
    assert(fname[fname_len] == '\0'); // make sure we found the actual length

    if(!sm_appendPath(&wc_fpath_len, wc_fpath, sizeof(fpath), fpath, fname_len, fname)) {
        return SDL_ENUM_FAILURE;
    }

    // ensure the item is a file
    SDL_PathInfo info = { 0 };
    if(!SDL_GetPathInfo(fpath, &info)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get SDL path info for %s: %s (%s:%s)", fpath, SDL_GetError(), __FILE_NAME__, __FUNCTION__);
        return SDL_ENUM_FAILURE;
    }
    if(info.type != SDL_PATHTYPE_FILE) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Found unexpected item in assets dir: %s", fname);
        return SDL_ENUM_FAILURE;
    }

    // get the file stem
    char fstem[SM_MAX_PATH*2] = { 0 };
    if(!sm_getFileStem(fname_len, fname, sizeof(fstem), fstem)) {
        return SDL_ENUM_FAILURE;
    }

    // get the file extension
    char ext[SM_MAX_PATH*2] = { 0 };
    if (!sm_getFileExt(wc_fpath_len, (void*)wc_fpath, sizeof(ext), ext)) {
        return SDL_ENUM_FAILURE;
    }

    // try to map the file stem to the LUT index
    size_t index = 0;
    if (strncmp("foo.vert", fstem, 8) == 0) {
        index = SM_SHADER_FOO_VERT;
    } else {
        // we're only handling shaders for now
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Found unexpected asset: %s", fname);
        return SDL_ENUM_FAILURE;
    }

    // check the file extension
    if(strncmp(".json", ext, 5) == 0 ||
        strncmp(".dxil", ext, 5) == 0 ||
        strncmp(".spv", ext, 4) == 0
    ) {
        if (!sm_readFile(state, fpath)) {
            return SDL_ENUM_FAILURE;
        }
    } else {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Found unexpected asset: %s", fname);
        return SDL_ENUM_FAILURE;
    }

#endif
    return SDL_ENUM_CONTINUE;
}

bool sm_initAssets(sm_state* state) {
    // allocate 2 bytes for each allowed character in the path so we can safely store the
    // wide string result in the narrow string
    char assets_path[SM_MAX_PATH*2] = { 0 };
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

    // this is a good spot to initialize asset-related fields in the app state
    state->shaders_buf = malloc(sizeof(char) * SM_MAX_SHADERS_BUF);
    if(!state->shaders_buf) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Heap allocation failed (%s:%s)", __FILE_NAME__, __FUNCTION__);
        return false;
    }
    state->shader_lookup = malloc(sizeof(sm_shaderinfo) * SM_MAX_SHADERS);
    if(!state->shader_lookup) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Heap allocation failed (%s:%s)", __FILE_NAME__, __FUNCTION__);
        goto err1;
    }
    state->shaders_len = 0;
    state->shader_lut_len = 0;

    // walk the dir
    struct sm_assets_state assets_state = {
        .appstate = state,
        .assets_path = assets_path,
    };
    if(!SDL_EnumerateDirectory(assets_path, sm_walkAssetsDir, &assets_state)) {
        goto err2;
    }

    return true;

err2:
    free(state->shader_lookup);
err1:
    free(state->shaders_buf);
    return false;
}

void sm_deinitAssets(sm_state* state) {
    free(state->shader_lookup);
    free(state->shaders_buf);
}
