#ifndef LIB_UNIDEPTH
#define LIB_UNIDEPTH

float unidepth_linearize_depth(vec2 uv, sampler2D reg_depth, sampler2D dh_depth, float reg_near, float reg_far, float dh_near, float dh_far) {
    float rd = texture(reg_depth, uv).r;
    float dd = texture(dh_depth, uv).r;

    if (rd == 1.0 && dd == 1.0) { return -1.0; }

    float r = ((2.0 * reg_near * reg_far) / (reg_far + reg_near - (rd* 2.0 - 1.0) * (reg_far - reg_near)));
    float d = ((2.0 * dh_near * dh_far) / (dh_far + dh_near - (dd * 2.0 - 1.0) * (dh_far - dh_near)));

    return min(r, d);
}

float unidepth_linearize_depth(float depthval, float near, float far) {
    return ((2.0 * near * far) / (far + near - (depthval * 2.0 - 1.0) * (far - near))) / far;
}

vec3 unidepth_get_viewspace_position(vec2 uv, sampler2D reg_depth, sampler2D dh_depth, mat4 proj_inv, mat4 dh_proj_inv) {
    vec3 reg_clip_space = vec3(uv, texture(reg_depth, uv).r) * 2.0 - 1.0;
    vec4 reg_view_w = proj_inv * vec4(reg_clip_space, 1.0);
    vec3 reg_view = reg_view_w.xyz / reg_view_w.w;

    vec3 dh_clip_space = vec3(uv, texture(dh_depth, uv).r) * 2.0 - 1.0;
    vec4 dh_view_w = dh_proj_inv * vec4(dh_clip_space, 1.0);
    vec3 dh_view = dh_view_w.xyz / dh_view_w.w;

    if (reg_view.z > dh_view.z) {
        return reg_view;
    }
    return dh_view;
}

vec2 unidepth_get_both_view_z(vec2 uv, sampler2D reg_depth, sampler2D dh_depth, mat4 proj_inv, mat4 dh_proj_inv) {
    vec3 reg_clip_space = vec3(uv, texture(reg_depth, uv).r) * 2.0 - 1.0;
    vec4 reg_view_w = proj_inv * vec4(reg_clip_space, 1.0);
    vec3 reg_view = reg_view_w.xyz / reg_view_w.w;

    vec3 dh_clip_space = vec3(uv, texture(dh_depth, uv).r) * 2.0 - 1.0;
    vec4 dh_view_w = dh_proj_inv * vec4(dh_clip_space, 1.0);
    vec3 dh_view = dh_view_w.xyz / dh_view_w.w;

    return vec2(reg_view.z, dh_view.z);
}

vec3 unidepth_get_viewspace_position(vec2 uv, float reg_depth, float dh_depth, mat4 proj_inv, mat4 dh_proj_inv) {
    vec3 reg_clip_space = vec3(uv, reg_depth) * 2.0 - 1.0;
    vec4 reg_view_w = proj_inv * vec4(reg_clip_space, 1.0);
    vec3 reg_view = reg_view_w.xyz / reg_view_w.w;

    vec3 dh_clip_space = vec3(uv, dh_depth) * 2.0 - 1.0;
    vec4 dh_view_w = dh_proj_inv * vec4(dh_clip_space, 1.0);
    vec3 dh_view = dh_view_w.xyz / dh_view_w.w;

    if (reg_view.z > dh_view.z) {
        return reg_view;
    }
    return dh_view;
}

// Returns the world-space position relative to the player's eyes
vec3 unidepth_get_worldspace_position(vec2 uv, sampler2D reg_depth, sampler2D dh_depth, mat4 proj_inv, mat4 dh_proj_inv, mat4 model_view_inv) {
    return mat3(model_view_inv) * unidepth_get_viewspace_position(uv, reg_depth, dh_depth, proj_inv, dh_proj_inv);
}

// // Gets the z-coordinate of any pixel on the screen, regardless of if it contains regular or DH terrain.
// // 
// // Returns -1 if no terrain at all is found.
// float get_z_unified(vec2 uv, sampler2D regular_depth, sampler2D dh_depth, mat4 proj_inv, mat4 dh_proj_inv) {
//     float reg = texture(regular_depth, uv).r;
//     float dh = texture(dh_depth, uv).r;

//     // return UNIDEPTH_LIN_DEPTH(reg, near, far);
//     // return UNIDEPTH_LIN_DEPTH(dh, dh_near, dh_far);
//     // return min(UNIDEPTH_LIN_DEPTH(reg, near, far), UNIDEPTH_LIN_DEPTH(dh, dh_near, dh_far));
//     return min(-unidepth_get_viewspace_position(uv, reg, proj_inv).z, -unidepth_get_viewspace_position(uv, dh, dh_proj_inv).z);
//     // return -unidepth_get_viewspace_position(uv, dh, dh_proj_inv).z;
//     // if (reg == 1.0) {
//     //     return UNIDEPTH_LIN_DEPTH(dh, dh_near, dh_far);
//     // } else if (dh == 1.0) {
//     //     return -1.0;
//     // } else {
//     //     return UNIDEPTH_LIN_DEPTH(reg, near, far);
//     // }
// }

#endif