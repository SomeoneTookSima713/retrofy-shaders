#ifndef LIB_WEATHER_ENC
#define LIB_WEATHER_ENC

#define WEATHERENC_BIT_IS_SNOW 0x80000000u

// Bit format:
// 1AAAAAAA BBBBBBBB GGGGGGGG RRRRRRRR
uint weatherenc_encode_regular_weather(vec4 color) {
    return WEATHERENC_BIT_IS_SNOW | uint(color.a * 127.0) | (packUnorm4x8(color) & 0x00ffffffu);
}

// Bit format:
// 0DDDDDDD DDDDDDDD DDDDYYYY YYXXXXXX
// D - Depth
// Y - Normal Y
// X - Normal X
uint weatherenc_encode_refracting_rain(vec2 normal_xy, float depth) {
    normal_xy = clamp(fma(normal_xy, vec2(0.5), vec2(0.5)), vec2(0.0), vec2(1.0)) * 63.0;

    return uint(normal_xy.x)
        | (uint(normal_xy.y) << 6u)
        | (uint(clamp(gl_FragCoord.z, 0.0, 1.0) * 524287.0) << 12u);
}

bool weatherenc_is_refracting_rain(uint encoded) {
    return !bool(encoded & WEATHERENC_BIT_IS_SNOW);
}

vec4 weatherenc_decode_regular_weather(uint encoded) {
    vec4 val = unpackUnorm4x8(encoded);
    val.a = float((encoded >> 24u) & 0x7fu) / 127.0;
    return val;
}

vec3 weatherenc_decode_refracting_rain(uint encoded) {
    uvec3 uints = (uvec3(encoded, encoded, encoded) >> uvec3(0u, 6u, 12u)) & uvec3(63u, 63u, 0x7ffffu);
    vec3 data = vec3(uints) / vec3(63.0, 63.0, 524287.0);
    data.xy = data.xy * 2.0 - 1.0;
    return data;
}

#endif