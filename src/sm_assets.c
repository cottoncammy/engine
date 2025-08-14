#include <SDL3/SDL_filesystem.h>
#include <SDL3/SDL_log.h>

#ifdef SDL_PLATFORM_WIN32
# include <windows.h>
# include <pathcch.h>
# include <winerror.h>
#endif
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "sm_assets.h"

#ifdef SDL_PLATFORM_WIN32
static bool sm_getWideString(const char *narrow, size_t dstlen, wchar_t *dst) {
    size_t converted = 0;
    if (mbstowcs_s(&converted, dst, dstlen / sizeof(wchar_t), narrow, strlen(narrow)) != 0) {
        goto err;
    }
    if(converted != strlen(narrow)+1) {
        goto err;
    }

    return true;
    err:
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert narrow character string to wide character string: file %s", __FILE__);
        return false;
}

static bool sm_getNarrowString(const wchar_t *wide, size_t dstlen, char *dst) {
    size_t converted = 0;
    if (wcstombs_s(&converted, dst, dstlen, wide, dstlen-1) != 0) {
        goto err;
    }
    if(converted != wcslen(wide)+1) {
        goto err;
    }

    return true;
    err:
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to convert wide character string to narrow character string: file %s", __FILE__);
        return false;
}
#endif

static bool sm_getAssetsPath(size_t dstlen, char *dst) {
    const char *bin = SDL_GetBasePath();
#ifdef SDL_PLATFORM_WIN32
    if(strcpy_s(dst, dstlen / 2, bin) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy string: file %s", __FILE__);
        return false;
    }
    wchar_t wc_dst[MAX_PATH+1] = { 0 };
    if(!sm_getWideString(dst, sizeof(wc_dst), wc_dst)) {
        return false;
    }
    const char *append = "assets";
    wchar_t wc_append[MAX_PATH+1] = { 0 };
    if(!sm_getWideString(append, sizeof(wc_append), wc_append)) {
        return false;
    }

    const HRESULT hresult = PathCchAppend(wc_dst, sizeof(wc_dst), wc_append);
    if (FAILED(hresult)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to append path: error code %ld, file %s", HRESULT_CODE(hresult), __FILE__);
        return false;
    }
    char nc_dst[(MAX_PATH+1) * 2] = { 0 };
    if(!sm_getNarrowString(wc_dst, dstlen, dst)) {
        return false;
    }

    return true;
#else
# error Unsupported platform
#endif
}

static struct sm_assets_state {
    sm_state *appstate;
    const char *assets_path;
} sm_assets_state;

static SDL_EnumerationResult SDLCALL sm_walkAssetsDir(void *userdata, const char *dirname, const char *fname) {
    struct sm_assets_state *state = (struct sm_assets_state*)userdata;
    return SDL_ENUM_SUCCESS;
}

bool sm_initAssets(sm_state* state) {
#ifdef SDL_PLATFORM_WIN32
    char assets_path[(MAX_PATH+1) * 2] = { 0 };
#endif
    if(!sm_getAssetsPath(sizeof(assets_path), assets_path)) {
        return false;
    }
    return true;
}

void sm_deinitAssets(sm_state* state) {

}
