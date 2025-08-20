#pragma once

#include <SDL3/SDL_gpu.h>

#include <stdbool.h>

#include "sm_entrypoint.h"

bool sm_createShader(const sm_state *const state, sm_shader_idx idx, SDL_GPUShader **dst);

bool sm_createGraphicsPipeline(const sm_state *const state,
							   SDL_GPUShader *const vert_shader,
							   SDL_GPUShader *const frag_shader,
							   SDL_GPUFillMode fill_mode, SDL_GPUGraphicsPipeline **dst);
