#pragma once

#define SM_MAX_ERRMSG 256
#define SM_MAX_FILE (100 * 1024)
#define SM_MAX_SHADERS 15

// the max number of shaders * max file size * the number of shader formats
#define SM_MAX_SHADERS_BUF (SM_MAX_SHADERS * SM_MAX_FILE * 3)
#define SM_SIZEOF_SHADERS_BUF (sizeof(char) * SM_MAX_SHADERS_BUF)

#include <SDL3/SDL_gpu.h>
#include <SDL3/SDL_video.h>

typedef struct sm_shaderinfo {
    size_t dxil_offset;
    size_t dxil_len;
    size_t spv_offset;
    size_t spv_len;
    size_t json_offset;
    size_t json_len;
} sm_shaderinfo;

typedef struct sm_state {
    SDL_GPUDevice *device;
    SDL_Window *window;

    char *shaders_buf;
    size_t shaders_len;
    sm_shaderinfo *shaders_lookup;
    size_t shaders_lut_len;
} sm_state;
