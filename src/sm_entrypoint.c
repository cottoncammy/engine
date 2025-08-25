#include <SDL3/SDL.h>
#define SDL_MAIN_USE_CALLBACKS
#include <SDL3/SDL_main.h>

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#include "sm_assets.h"
#include "sm_build_config.h"
#include "sm_entrypoint.h"
#include "sm_gpu.h"

static bool sm_initGpuPipelines(sm_state *state) {
	SDL_GPUShader *vert_shader = NULL;
	if(!sm_createShader(state, TRIANGLE_VERT, &vert_shader)) {
		return false;
	}
	SDL_GPUShader *frag_shader = NULL;
	if(!sm_createShader(state, COLOR_FRAG, &frag_shader)) {
		goto err1;
	}

	if(!sm_createGraphicsPipeline(state, vert_shader, frag_shader, SDL_GPU_FILLMODE_FILL,
								  &state->fill_pipeline)) {
		goto err2;
	}
#ifndef NDEBUG
	if(!sm_createGraphicsPipeline(state, vert_shader, frag_shader, SDL_GPU_FILLMODE_LINE,
								  &state->line_pipeline)) {
		goto err3;
	}
#endif

	SDL_ReleaseGPUShader(state->device, frag_shader);
	SDL_ReleaseGPUShader(state->device, vert_shader);
	return true;
err3:
	SDL_ReleaseGPUGraphicsPipeline(state->device, state->fill_pipeline);
err2:
	SDL_ReleaseGPUShader(state->device, frag_shader);
err1:
	SDL_ReleaseGPUShader(state->device, vert_shader);
	return false;
}

static void sm_deinitGpuPipelines(sm_state *state) {
	SDL_ReleaseGPUGraphicsPipeline(state->device, state->fill_pipeline);
#ifndef NDEBUG
	SDL_ReleaseGPUGraphicsPipeline(state->device, state->line_pipeline);
#endif
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv) {
	if(!SDL_SetAppMetadata(SM_INFO_STRING, SM_VERSION_STRING,
						   "dev.cottoncammy.submachine")) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to set app metadata: %s",
					 SDL_GetError());
		return SDL_APP_FAILURE;
	}

	if(!SDL_Init(SDL_INIT_VIDEO)) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to initialize SDL: %s",
					 SDL_GetError());
		return SDL_APP_FAILURE;
	}

	const SDL_GPUShaderFormat device_flags =
		SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_SPIRV;
	SDL_GPUDevice *device = SDL_CreateGPUDevice(device_flags, true, NULL);
	if(device == NULL) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create GPU device: %s",
					 SDL_GetError());
		goto err1;
	}

	SDL_WINDOWPOS_CENTERED;

	const SDL_WindowFlags window_flags = SDL_WINDOW_HIGH_PIXEL_DENSITY;
	SDL_Window *window = SDL_CreateWindow(SM_INFO_STRING, 960, 600, window_flags);
	if(!window) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create window: %s",
					 SDL_GetError());
		goto err2;
	}

	if(!SDL_ClaimWindowForGPUDevice(device, window)) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to create swapchain for window: %s",
					 SDL_GetError());
		goto err3;
	}

	*appstate = calloc(1, sizeof(sm_state));
	if(!*appstate) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to allocate heap memory (%s:%s)",
					 __FILE_NAME__, __FUNCTION__);
		goto err4;
	}

	sm_state *state = *appstate;
	state->device = device;
	state->window = window;
	if(!sm_initAssets(state)) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to initialize assets");
		goto err4;
	}
	if(!sm_initGpuPipelines(state)) {
		goto err5;
	}

	return SDL_APP_CONTINUE;
err5:
	sm_deinitAssets(state);
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
	sm_state *state = (sm_state *)appstate;
	SDL_GPUCommandBuffer *cmdbuf = SDL_AcquireGPUCommandBuffer(state->device);
	if(!cmdbuf) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to acquire command buffer: %s",
					 SDL_GetError());
		return SDL_APP_FAILURE;
	}

	SDL_GPUTexture *swapchain_tex = NULL;
	if(!SDL_WaitAndAcquireGPUSwapchainTexture(cmdbuf, state->window, &swapchain_tex, NULL,
											  NULL)) {
		SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Failed to acquire swapchain texture: %s",
					 SDL_GetError());
		return SDL_APP_FAILURE;
	}

	if(swapchain_tex) {
		SDL_GPUColorTargetInfo color_target_info = {0};
		color_target_info.texture = swapchain_tex;
		color_target_info.clear_color = (SDL_FColor){0.0f, 0.0f, 0.0f, 1.0f};
		color_target_info.load_op = SDL_GPU_LOADOP_CLEAR;
		color_target_info.store_op = SDL_GPU_STOREOP_STORE;

		SDL_GPURenderPass *renderpass =
			SDL_BeginGPURenderPass(cmdbuf, &color_target_info, 1, NULL);
		SDL_BindGPUGraphicsPipeline(renderpass, state->fill_pipeline);
		SDL_DrawGPUPrimitives(renderpass, 3, 1, 0, 0);
		SDL_EndGPURenderPass(renderpass);
	}

	SDL_SubmitGPUCommandBuffer(cmdbuf);
	return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
	if(event->type == SDL_EVENT_QUIT) {
		return SDL_APP_SUCCESS;
	}
	return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
	sm_state *state = (sm_state *)appstate;
	sm_deinitGpuPipelines(state);
	sm_deinitAssets(state);
	SDL_ReleaseWindowFromGPUDevice(state->device, state->window);
	SDL_DestroyWindow(state->window);
	SDL_DestroyGPUDevice(state->device);
	free(state);
	SDL_Quit();
}
