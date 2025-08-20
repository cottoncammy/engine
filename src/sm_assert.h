#pragma once

#include <assert.h>

#define STRINGIFY(x) #x
#define EXPAND_STRINGIFY(x) STRINGIFY(x)

#define sm_static_assert(expr)                                                           \
	static_assert(expr, "Assertion failed: " #expr ", file " __FILE__                    \
						", line " EXPAND_STRINGIFY(__LINE__))
