#ifndef LIB_PIXELATION
#define LIB_PIXELATION

#if (MC_GL_VENDOR_AMD || MC_GL_VENDOR_INTEL || MC_GL_VENDOR_ATI) && defined MC_GL_ARB_derivative_control
    #ifndef EXT_USED_GL_ARB_derivative_control
        #define EXT_USED_GL_ARB_derivative_control
        #extension GL_ARB_derivative_control: require
    #endif

    #define DERIVATIVE_dFdx dFdxFine
    #define DERIVATIVE_dFdy dFdyFine
#else
    #define DERIVATIVE_dFdx dFdx
    #define DERIVATIVE_dFdy dFdy
#endif

#include "/lib/dither.glsl"

// Computes axis-aligned screen space offset to texel center.
// https://forum.unity.com/threads/the-quest-for-efficient-per-texel-lighting.529948/#post-7536023
vec2 compute_texel_offset(vec2 uv, vec4 texelSize) {
    // 1. Calculate how much the texture UV coords need to shift to be at the center of the nearest texel.
    vec2 uvCenter = (floor(uv * texelSize.zw) + 0.5) * texelSize.xy;
    vec2 dUV = uvCenter - uv;

    // 2. Calculate how much the texture coords vary over fragment space.
    //     This essentially defines a 2x2 matrix that gets texture space (UV) deltas from fragment space (ST) deltas.
    vec2 dUVdS = DERIVATIVE_dFdx(uv);
    vec2 dUVdT = DERIVATIVE_dFdy(uv);

    if (abs(dUVdS) + abs(dUVdT) == vec2(0.0)) return vec2(0.0);

    // 3. Invert the texture delta from fragment delta matrix. Where the magic happens.
    mat2x2 dSTdUV = mat2x2(dUVdT[1], -dUVdT[0], -dUVdS[1], dUVdS[0]) * (1.0 / (dUVdS[0] * dUVdT[1] - dUVdT[0] * dUVdS[1]));

    // 4. Convert the texture delta to fragment delta.
    vec2 dST = dUV * dSTdUV;
    return dST;
}

vec2 compute_texel_offset(sampler2D tex, vec2 uv, float pixelation_mult) {
    vec2 texSize = textureSize(tex, 0) * pixelation_mult;
    vec4 texelSize = vec4(1.0 / texSize.xy, texSize.xy);

    return compute_texel_offset(uv, texelSize);
}

// Computes axis-aligned screen space offset to texel center.
// https://forum.unity.com/threads/the-quest-for-efficient-per-texel-lighting.529948/#post-7536023
vec2 compute_dithered_texel_offset(vec2 uv, vec4 texelSize, vec2 worldspace_surface_position, float computed_value_diff) {
    // 1. Calculate how much the texture UV coords need to shift to be at the center of the nearest texel.
    vec2 uvCenter = (floor(uv * texelSize.zw) + 0.5) * texelSize.xy;
    vec2 dUV = uvCenter - uv;

    float dither = dither8x8(worldspace_surface_position, mod(computed_value_diff, 1.0));

    // Recalculate the uv stuff for dithering
    uvCenter = (floor(uv * texelSize.zw) + 0.5 - vec2(dither) * sign(dUV + 0.5 * texelSize.xy) * floor(computed_value_diff)) * texelSize.xy;
    dUV = uvCenter - uv;

    // 2. Calculate how much the texture coords vary over fragment space.
    //     This essentially defines a 2x2 matrix that gets texture space (UV) deltas from fragment space (ST) deltas.
    vec2 dUVdS = DERIVATIVE_dFdx(uv);
    vec2 dUVdT = DERIVATIVE_dFdy(uv);

    if (abs(dUVdS) + abs(dUVdT) == vec2(0.0)) return vec2(0.0);

    // 3. Invert the texture delta from fragment delta matrix. Where the magic happens.
    mat2x2 dSTdUV = mat2x2(dUVdT[1], -dUVdT[0], -dUVdS[1], dUVdS[0]) * (1.0 / (dUVdS[0] * dUVdT[1] - dUVdT[0] * dUVdS[1]));

    // 4. Convert the texture delta to fragment delta.
    vec2 dST = dUV * dSTdUV;
    return dST;
}

vec2 compute_dithered_texel_offset(sampler2D tex, vec2 uv, float pixelation_mult, vec2 worldspace_surface_position, float base_value_gradient) {
    vec2 texSize = textureSize(tex, 0) * pixelation_mult;
    vec4 texelSize = vec4(1.0 / texSize.xy, texSize.xy);

    return compute_dithered_texel_offset(uv, texelSize, worldspace_surface_position, base_value_gradient * 128.0);
}

vec4 texel_snap(vec4 value, vec2 texelOffset) {
    if (texelOffset == vec2(0.0)) return value;
    vec4 dx = DERIVATIVE_dFdx(value);
    vec4 dy = DERIVATIVE_dFdy(value);

    vec4 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
    valueOffset = clamp(valueOffset, -1.0, 1.0);

    return value + valueOffset;
}

vec3 texel_snap(vec3 value, vec2 texelOffset) {
    if (texelOffset == vec2(0.0)) return value;
    vec3 dx = DERIVATIVE_dFdx(value);
    vec3 dy = DERIVATIVE_dFdy(value);

    vec3 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
    valueOffset = clamp(valueOffset, -1.0, 1.0);

    return value + valueOffset;
}

vec2 texel_snap(vec2 value, vec2 texelOffset) {
    if (texelOffset == vec2(0.0)) return value;
    vec2 dx = DERIVATIVE_dFdx(value);
    vec2 dy = DERIVATIVE_dFdy(value);

    vec2 valueOffset = dx * texelOffset.x + dy * texelOffset.y;
    valueOffset = clamp(valueOffset, -1.0, 1.0);

    return value + valueOffset;
}

float texel_snap(float value, vec2 texelOffset) {
    if (texelOffset == vec2(0.0)) return value;
    float dx = DERIVATIVE_dFdx(value);
    float dy = DERIVATIVE_dFdy(value);

    float valueOffset = dx * texelOffset.x + dy * texelOffset.y;
    valueOffset = clamp(valueOffset, -1.0, 1.0);

    return value + valueOffset;
}

#endif