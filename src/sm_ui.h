#pragma once

#include <stdbool.h>
#include <stdint.h>

#define SM_UI_MAX_NODES 100

typedef enum {
    STACKING_CONTEXT,
    RECT,
} sm_ui_node_type;

typedef struct __attribute__((aligned(8))) {
    float x1;
    float y1;
    float x2;
    float y2;
} sm_rect;

typedef struct __attribute__((aligned(8))) {
    float x;
    float y;
} sm_point;

typedef struct __attribute__((aligned(8))) {
    float r;
    float g;
    float b;
    float a;
} sm_color;

typedef struct {
    uint32_t id;
    sm_ui_node_type type;
    sm_rect clip_bounds;
    uint32_t spatial_id;
    
    size_t parent_idx;
    size_t prev_sibling_idx;
    size_t next_sibling_idx;
    size_t first_child_idx;
    size_t last_child_idx;

    union {
        struct {
            sm_point origin;
            sm_point offset;
            // filter stuff here
        } stacking_context;

        struct {

        } scroll_frame;

        struct {
            sm_rect bounds;
            sm_color color;
        } rect;
    } data;
} sm_ui_node;

typedef struct {
    sm_ui_node **nodes;
    size_t nodes_len;
    size_t nodes_capacity;
    size_t free_head;
    size_t free_len;
} sm_ui_tree;

typedef enum {
    REFERENCE_FRAME,
    SCROLL_FRAME,
} sm_spatial_node_type;

typedef struct {
    uint32_t id;
    
    union {
        struct {
            sm_rect viewport;
            float width;
            float height;
        } scroll_frame;
    } data;
} sm_spatial_node;

typedef struct {
    sm_spatial_node **nodes;
} sm_spatial_tree;

// entrypoint
typedef struct {

} sm_ui_state;
