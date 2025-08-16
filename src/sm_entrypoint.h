#pragma once

#define SM_MAX_ERRMSG 256

#include <SDL3/SDL_gpu.h>
#include <SDL3/SDL_video.h>

typedef struct sm_state {
    SDL_GPUDevice *device;
    SDL_Window *window;
} sm_state;
