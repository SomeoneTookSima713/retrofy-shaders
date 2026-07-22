#ifndef FX_EASY_DITHER
#define FX_EASY_DITHER

#include "/lib/dither.glsl"
#include "/lib/colors.glsl"

vec3 dither_color_4x4(vec2 position, vec3 color, float color_amount) {
    vec3 hsv = rgb2hsv(color);
    vec3 floored = floor(hsv * color_amount) / color_amount;
    vec3 ceiled = ceil(hsv * color_amount) / color_amount;

    return hsv2rgb(mix(floored, ceiled, dither4x4(position, (hsv - floored) / (ceiled - floored))));
}

vec3 dither_color_hsv_4x4(vec2 position, vec3 hsv, float color_amount) {
    vec3 floored = floor(hsv * color_amount) / color_amount;
    vec3 ceiled = ceil(hsv * color_amount) / color_amount;

    return mix(floored, ceiled, dither4x4(position, (hsv - floored) / (ceiled - floored)));
}

#endif