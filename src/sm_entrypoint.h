#pragma once

#include <SDL3/SDL_gpu.h>
#include <SDL3/SDL_video.h>

typedef struct sm_state {
    SDL_GPUDevice *device;
    SDL_Window *window;
} sm_state;
