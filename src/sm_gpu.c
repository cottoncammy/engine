#include <SDL3/SDL_error.h>
#include <SDL3/SDL_log.h>

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "SDL3/SDL_gpu.h"
#include "sm_assert.h"
#include "sm_gpu.h"

static SDL_GPUShaderStage sm_shader_stages[2] = {
    SDL_GPU_SHADERSTAGE_VERTEX,
    SDL_GPU_SHADERSTAGE_FRAGMENT,
};

sm_static_assert(sizeof(char) == sizeof(uint8_t));

static bool sm_copyShaderBytes(const char *const src, size_t offset, size_t dstlen, uint8_t *const dst) {
    const errno_t errnum = memcpy_s(dst, dstlen, src + offset, dstlen);
    if(errnum != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errnum) != 0);
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy shader buffer data: %s (%s:%s)", errmsg, __FILE_NAME__, __FUNCTION__);
        return false;
    }
    return true;
}

bool sm_createShader(const sm_state *const state, sm_shader_idx idx, SDL_GPUShader **dst) {
    assert(state->shaders_lut_len > idx);
    const sm_shaderinfo *info = state->shaders_lookup[idx];
    assert(info);

    size_t code_offset = 0;
    size_t code_size = 0;
    SDL_GPUShaderFormat format = SDL_GPU_SHADERFORMAT_INVALID;
    const SDL_GPUShaderFormat formats = SDL_GetGPUShaderFormats(state->device);
    if(formats & SDL_GPU_SHADERFORMAT_DXIL) {
        code_offset = info->dxil_offset;
        code_size = info->dxil_len;
        format = SDL_GPU_SHADERFORMAT_DXIL;
    } else if(formats & SDL_GPU_SHADERFORMAT_SPIRV) {
        code_offset = info->spv_offset;
        code_size = info->spv_len;
        format = SDL_GPU_SHADERFORMAT_SPIRV;
    } else {
        __builtin_unreachable();
    }

    uint8_t *code = calloc(code_size, sizeof(uint8_t));
    if(!sm_copyShaderBytes(state->shaders_buf, code_offset, code_size, code)) {
        return false;
    }
    const SDL_GPUShaderCreateInfo createinfo = {
        .code_size = code_size,
        .code = code,
        .entrypoint = "main",
        .format = format,
        .stage = sm_shader_stages[idx >> 1],
        .num_samplers = 0,
        .num_storage_textures = 0,
        .num_storage_buffers = 0,
        .num_uniform_buffers = 0,
        .props = 0,
    };
    SDL_GPUShader *shader = SDL_CreateGPUShader(state->device, &createinfo);
    if(!shader) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL GPU shader %d: %s", idx, SDL_GetError());
        return false;
    }

    *dst = shader;
    return true;
}
