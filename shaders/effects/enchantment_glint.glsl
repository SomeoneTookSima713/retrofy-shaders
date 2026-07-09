#ifndef FX_ENCHANT_GLINT
#define FX_ENCHANT_GLINT

uniform usampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex9;
// uniform sampler2D colortex10;

void decode_glint_mask(in uint mask_value, out bool is_glint, out bool is_gbuffers_hand) {
    is_glint = bool(mask_value & 1u);
    is_gbuffers_hand = bool(mask_value & 2u);
}

void decode_glint_mask(in uint mask_value, out bool is_glint, out bool is_gbuffers_hand, out bool is_unblurred) {
    is_glint = bool(mask_value & 1u);
    is_gbuffers_hand = bool(mask_value & 2u);
    is_unblurred = bool(mask_value & 4u);
}

void decode_glint_mask(in uint mask_value, out bool is_glint, out bool is_gbuffers_hand, out bool is_unblurred, out float enchantment_effect_luma) {
    is_glint = bool(mask_value & 1u);
    is_gbuffers_hand = bool(mask_value & 2u);
    is_unblurred = bool(mask_value & 4u);
    enchantment_effect_luma = float(mask_value >> 4u) / 15.0;
}

void read_and_decode_glint_mask(in ivec2 coords, out bool is_glint, out bool is_gbuffers_hand) {
    decode_glint_mask(texelFetch(colortex5, coords, 0).r, is_glint, is_gbuffers_hand);
}

void read_and_decode_glint_mask(in ivec2 coords, out bool is_glint, out bool is_gbuffers_hand, out bool is_unblurred) {
    decode_glint_mask(texelFetch(colortex5, coords, 0).r, is_glint, is_gbuffers_hand, is_unblurred);
}

void read_and_decode_glint_mask(in ivec2 coords, out bool is_glint, out bool is_gbuffers_hand, out bool is_unblurred, out float enchantment_effect_luma) {
    decode_glint_mask(texelFetch(colortex5, coords, 0).r, is_glint, is_gbuffers_hand, is_unblurred, enchantment_effect_luma);
}

uint encode_glint_mask(in bool is_glint, in bool is_gbuffers_hand, in float enchantment_effect_luma) {
    return uint(is_glint) | (uint(is_gbuffers_hand) << 1u) | (uint(enchantment_effect_luma * 15.0) << 4u);
}

uint blur_glint_mask(ivec2 coords, usampler2D mask, const int radius, const int mipmap_level, const bool y_instead_of_x) {
    coords = coords >> ivec2(mipmap_level);
    const int radius_mip = radius >> mipmap_level;

    uint result = 0u;

    for (int i = 0; i <= radius_mip << 1; i++) {
        result |= texelFetch(mask, coords + (y_instead_of_x ? ivec2(0, i - radius_mip) : ivec2(i - radius_mip, 0)), mipmap_level).r;
    }

    return result & (~4u);
}

vec3 blur_glint_color(ivec2 coords, sampler2D color, usampler2D mask, int blur_radius_px, const bool y_instead_of_x) {
    // int offset = blur_radius_px;
    
    vec4 avg_regular = vec4(0.0);
    vec4 avg_hand = vec4(0.0);
    
    for (int i = 1; i <= blur_radius_px * 2 + 1; i++) {
        bool is_glint, is_gbuffers_hand;
        ivec2 curr_offset = y_instead_of_x ? ivec2(0, (i>>1) * (bool(i&1) ? -1 : 1)) : ivec2((i>>1) * (bool(i&1) ? -1 : 1), 0);
        read_and_decode_glint_mask(coords + curr_offset, is_glint, is_gbuffers_hand);
        vec3 pixel_color = texelFetch(color, coords + curr_offset, 0).rgb;

        avg_regular = max(avg_regular, is_glint ? vec4(pixel_color, 1.0) : vec4(0.0));
        avg_hand = max(avg_hand, is_gbuffers_hand ? vec4(pixel_color, 1.0) : vec4(0.0));
    }

    return avg_hand.a > 0.0 ? avg_hand.rgb / avg_hand.a : avg_regular.rgb / avg_regular.a;
}

float blur_glint_depth(ivec2 coords, sampler2D depth, const int radius, const int mipmap_level, const bool y_instead_of_x) {
    coords = coords >> ivec2(mipmap_level);
    const int radius_mip = radius >> mipmap_level;

    float result = 1000.0;

    for (int i = 0; i <= radius_mip << 1; i++) {
        result = min(result, texelFetch(depth, coords + (y_instead_of_x ? ivec2(0, i - radius_mip) : ivec2(i - radius_mip, 0)), mipmap_level).r);
    }

    return result;
}

#endif