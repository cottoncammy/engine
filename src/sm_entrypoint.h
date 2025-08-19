#pragma once

#include <SDL3/SDL_gpu.h>
#include <SDL3/SDL_video.h>

#include <stdint.h>

#include "sm_assert.h"

#define SM_MAX_ERRMSG 256
#define SM_MAX_FILE (100 * 1024)
#define SM_MAX_SHADERS 20

// the max number of shaders * max file size * the number of shader formats
#define SM_MAX_SHADERS_BUF (SM_MAX_SHADERS * SM_MAX_FILE * 3)

// make sure the word boundary is 64 bits
sm_static_assert(sizeof(void*) == 8);

typedef struct {
    size_t json_offset;
    size_t json_len;
    size_t dxil_offset;
    size_t dxil_len;
    size_t spv_offset;
    size_t spv_len;
} sm_shaderinfo;

typedef enum {
    TRIANGLE_VERT = (0 << 1) | 0,
    COLOR_FRAG = (1 << 1) | 1,
} sm_shader_idx;

typedef struct {
    SDL_GPUDevice *device;
    SDL_Window *window;
    SDL_GPUGraphicsPipeline *fill_pipeline;
#ifndef NDEBUG
    SDL_GPUGraphicsPipeline *line_pipeline;
#endif
    char *shaders_buf;
    size_t shaders_len;
    sm_shaderinfo **shaders_lookup;
    size_t shaders_lut_len;
} sm_state;
