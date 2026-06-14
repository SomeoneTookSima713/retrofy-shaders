#ifndef LIB_POSTERIZE
#define LIB_POSTERIZE

#define POSTERIZE_TOWARDS_ZERO(color, color_amount) sign(color)*floor(abs(color) * color_amount) / color_amount
#define POSTERIZE_AWAY_FROM_ZERO(color, color_amount) sign(color)*ceil(abs(color) * color_amount) / color_amount

vec4 posterize(vec4 color, float color_amount) {
    return floor(color * color_amount) / color_amount;
}

vec3 posterize(vec3 color, float color_amount) {
    return floor(color * color_amount) / color_amount;
}

vec2 posterize(vec2 color, float color_amount) {
    return floor(color * color_amount) / color_amount;
}

float posterize(float color, float color_amount) {
    return floor(color * color_amount) / color_amount;
}

vec4 posterize_ceil(vec4 color, float color_amount) {
    return ceil(color * color_amount) / color_amount;
}

vec3 posterize_ceil(vec3 color, float color_amount) {
    return ceil(color * color_amount) / color_amount;
}

vec2 posterize_ceil(vec2 color, float color_amount) {
    return ceil(color * color_amount) / color_amount;
}

float posterize_ceil(float color, float color_amount) {
    return ceil(color * color_amount) / color_amount;
}

#endif