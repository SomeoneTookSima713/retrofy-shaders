#ifndef LIB_COLORS
#define LIB_COLORS

#include "/lib/adam_colors.glsl"

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = c.g >= c.b ? vec4(c.gb, K.xy) : vec4(c.bg, K.wz);
    vec4 q = c.r >= p.x ? vec4(c.r, p.yzx) : vec4(p.xyw, c.r);

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb2oklab(vec3 rgb) {
    return SRGB_TO_OKLAB(rgb);
}

vec3 oklab2rgb(vec3 oklab) {
    return OKLAB_TO_SRGB(oklab);
}

// Mixes two RGB colors using the OkLAB color space.
vec3 mix_colors(vec3 a, vec3 b, float t) {
    // return oklab2rgb(mix(rgb2oklab(a), rgb2oklab(b), t));
    return mix(a, b, t);
}
#endif