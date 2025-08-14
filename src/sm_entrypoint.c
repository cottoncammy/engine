#include <SDL3/SDL.h>
#define SDL_MAIN_USE_CALLBACKS
#include <SDL3/SDL_main.h>
#include <sm_build_config.h>

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "sm_assets.h"
#include "sm_entrypoint.h"

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv) {
    if(!SDL_SetAppMetadata(SM_INFO_STRING, SM_VERSION_STRING, "dev.cottoncammy.submachine")) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to set SDL app metadata: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if(!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    const SDL_GPUShaderFormat device_flags = SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_SPIRV;
    SDL_GPUDevice *device = SDL_CreateGPUDevice(device_flags, true, NULL);
    if(device == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL GPU device: %s", SDL_GetError());
        goto err1;
    }

    SDL_WINDOWPOS_CENTERED;

    const SDL_WindowFlags window_flags = SDL_WINDOW_HIGH_PIXEL_DENSITY;
    SDL_Window *window = SDL_CreateWindow(SM_INFO_STRING, 960, 600, window_flags);
    if(window == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL window: %s", SDL_GetError());
        goto err2;
    }

    if(!SDL_ClaimWindowForGPUDevice(device, window)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create swapchain for SDL window: %s", SDL_GetError());
        goto err3;
    }

    sm_state *state = malloc(sizeof(sm_state));
    if(state == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Heap allocation failed: state");
        goto err4;
    }
    state->device = device;
    state->window = window;
    appstate = (void **)&state;

    sm_initAssets(state);
    return SDL_APP_CONTINUE;
err4:
    SDL_ReleaseWindowFromGPUDevice(device, window);
err3:
    SDL_DestroyWindow(window);
err2:
    SDL_DestroyGPUDevice(device);
err1:
    SDL_Quit();
    return SDL_APP_FAILURE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    if(event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
    sm_state *state = (sm_state*) appstate;
    free(state);
    SDL_Quit();
}
