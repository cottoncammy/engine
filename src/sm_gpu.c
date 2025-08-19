#include <SDL3/SDL_error.h>
#include <SDL3/SDL_log.h>

#include <assert.h>
#include <stdint.h>
#include <string.h>

#include "sm_assert.h"
#include "sm_gpu.h"

static SDL_GPUShaderStage sm_shader_stages[2] = {
    SDL_GPU_SHADERSTAGE_VERTEX,
    SDL_GPU_SHADERSTAGE_FRAGMENT,
};

sm_static_assert(sizeof(char) == sizeof(uint8_t));

static bool sm_copyShaderBytes(const char *const src, size_t offset, size_t dstlen, uint8_t *const dst) {
    const errno_t errnum = memcpy_s(dst, sizeof(uint8_t) * dstlen, src + offset, dstlen);
    if(errnum != 0) {
        char errmsg[SM_MAX_ERRMSG] = { 0 };
        assert(strerror_s(errmsg, sizeof(errmsg), errnum) != 0);
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to copy shader buffer data: %s (%s:%s)", errmsg, __FILE_NAME__, __FUNCTION__);
        return false;
    }
    return true;
}

bool sm_createShader(const sm_state *const state, sm_shader_idx idx, SDL_GPUShader **dst) {
    assert(state->shaders_lut_len > (idx >> 1));
    const sm_shaderinfo *const info = state->shaders_lookup[idx >> 1];
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
    assert(code_offset < state->shaders_len);

    uint8_t *code = calloc(code_size, sizeof(uint8_t));
    if(!code) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to allocate heap memory (%s:%s)", __FILE_NAME__, __FUNCTION__);
        return false;
    }

    if(!sm_copyShaderBytes(state->shaders_buf, code_offset, code_size, code)) {
        return false;
    }
    const SDL_GPUShaderCreateInfo createinfo = {
        .code_size = code_size,
        .code = code,
        .entrypoint = "main",
        .format = format,
        .stage = sm_shader_stages[idx & 0x1],
        .num_samplers = 0,
        .num_storage_textures = 0,
        .num_storage_buffers = 0,
        .num_uniform_buffers = 0,
    };
    SDL_GPUShader *shader = SDL_CreateGPUShader(state->device, &createinfo);
    if(!shader) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL GPU shader %d: %s", idx, SDL_GetError());
        return false;
    }

    *dst = shader;
    return true;
}

bool sm_createGraphicsPipeline(const sm_state *const state, SDL_GPUShader *const vert_shader, SDL_GPUShader *const frag_shader, SDL_GPUFillMode fill_mode, SDL_GPUGraphicsPipeline **dst) {
    const SDL_GPUGraphicsPipelineCreateInfo info = {
        .vertex_shader = vert_shader,
        .fragment_shader = frag_shader,
        .primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .rasterizer_state = {
            .fill_mode = fill_mode,
        },
        .target_info = {
            .color_target_descriptions = (SDL_GPUColorTargetDescription[]){
                {
                    .format = SDL_GetGPUSwapchainTextureFormat(state->device, state->window),
                },
            },
            .num_color_targets = 1,
        },
    };
    SDL_GPUGraphicsPipeline *pipeline = SDL_CreateGPUGraphicsPipeline(state->device, &info);
    if(!pipeline) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL GPU graphics pipeline: %s", SDL_GetError());
        return false;
    }

    *dst = pipeline;
    return true;
}
