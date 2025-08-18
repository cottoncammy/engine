#pragma once

#include <stdbool.h>

#include "sm_entrypoint.h"

bool sm_initAssets(sm_state *const state);

void sm_deinitAssets(sm_state *const state);
