#include <SDL3/SDL.h>
#define SDL_MAIN_USE_CALLBACKS
#include <SDL3/SDL_main.h>
#include <sm_config.h>

#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#include "sm_entrypoint.h"

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv) {
    if(!SDL_SetAppMetadata(SUBMACHINE_NAME, SUBMACHINE_VERSION_STRING, "dev.cottoncammy.submachine")) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to set SDL app metadata: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if(!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_DisplayID display = SDL_GetPrimaryDisplay();
    if(display == 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get primary SDL display: %s", SDL_GetError());
        goto err1;
    }
    SDL_WINDOWPOS_CENTERED_DISPLAY(display);

    int32_t numDisplayModes = 0;
    SDL_DisplayMode **displayModes = SDL_GetFullscreenDisplayModes(display, &numDisplayModes);
    if(displayModes == NULL || numDisplayModes == 0) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to get SDL display modes: %s", SDL_GetError());
        goto err1;
    }

    size_t i = 0;
    for(; i < numDisplayModes; ++i) {
        SDL_DisplayMode *displayMode = displayModes[i];
        assert(displayMode != NULL);
    }
    assert(displayModes[i] == NULL);
    SDL_free((void *)displayModes);

    SDL_WindowFlags flags = 0;
    SDL_Window *window  = SDL_CreateWindow(SUBMACHINE_NAME, 500, 500, flags);
    if(window == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create SDL window: %s", SDL_GetError());
        goto err1;
    }

    struct sm_state *state = malloc(sizeof(struct sm_state));
    if(state == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to allocate heap memory for engine state");
        goto err2;
    }
    state->window = window;
    appstate = (void **) &state;

    return SDL_APP_CONTINUE;
err2:
    SDL_DestroyWindow(window);
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
    struct sm_state *state = (struct sm_state*) appstate;
    free(state);
    SDL_Quit();
}
