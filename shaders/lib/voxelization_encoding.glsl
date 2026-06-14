#ifndef VOXEL_ENCODE
#define VOXEL_ENCODE

#include "/effects/options.glsl"
#include "/lib/colors.glsl"

#define VE_PASSABILITY_POSX 1
#define VE_PASSABILITY_NEGX 2
#define VE_PASSABILITY_POSY 4
#define VE_PASSABILITY_NEGY 8
#define VE_PASSABILITY_POSZ 16
#define VE_PASSABILITY_NEGZ 32
#define VE_PASSABILITY_X 3
#define VE_PASSABILITY_Y 12
#define VE_PASSABILITY_Z 48
#define VE_PASSABILITY_ALL 63
#define VE_PASSABILITY_NONE 0

// Encoded Format:
// 
// _______1-________-__PPPPPP-FFFFGT_L
// 
// - L: is_light
// - P: passability_mask
// - T: tints_light
// - G: is_gbuffers
// - F: timestamp
struct VoxelInfo {
    bool is_light;
    bool is_passable;
    bool tints_light;
    bool is_gbuffers; 
    int timestamp;
    int passability_mask;
};

#define VE_VOXELINFO_IS_LIGHT 1
#define VE_VOXELINFO_TINTS_LIGHT 4
#define VE_VOXELINFO_IS_GBUFFERS 8
#define VE_VOXELINFO_TIMESTAMP 240
#define VE_VOXELINFO_PASSABILITY 16128
#define VE_VOXELINFO_SHIFT_TIMESTAMP 4
#define VE_VOXELINFO_SHIFT_PASSABILITY 8

vec4 decode_color_and_light(uint value) {
    float h = float((value & 0x000000FFu)) / 255.0;
    float s = float((value & 0x0000FF00u) >> 8) / 255.0;
    float v = float((value & 0x00FF0000u) >> 16) / 255.0;
    float l = float((value & 0x0F000000u) >> 24) / 15.0;

    // return vec4(hsv2rgb(vec3(h, s, v)), l);
    return vec4(h, s, v, l); // Actually RGB now instead of HSV
}

bool light_is_from_current_frame(VoxelInfo info, int frameCounter) {
    return info.timestamp == (frameCounter & 15) || info.timestamp == 256;
}

bool voxel_info_is_empty(VoxelInfo info) {
    return info.timestamp == 256;
}

vec4 decode_color_and_light_oklab(uint value) {
    float h = float((value & 0x000000FFu)) / 255.0;
    float s = float((value & 0x0000FF00u) >> 8) / 255.0;
    float v = float((value & 0x00FF0000u) >> 16) / 255.0;
    float l = float((value & 0x0F000000u) >> 24) / 15.0;

    // return vec4(rgb2oklab(hsv2rgb(vec3(h, s, v))), l);
    return vec4(h, s, v, l); // Actually RGB now instead of HSV
}

uint encode_color_and_light_voxel(vec4 value) {
    // We use HSV to utilise imageAtomicMax for getting the lightest average color of all block face's textures
    vec3 hsv = rgb2hsv(value.rgb);
    // hsv.z = 1.0;
    // uvec3 hsv_int = uvec3(hsv * 255.0);
    uvec3 hsv_int = uvec3(value.rgb * 255.0 * value.w); // Actually RGB now instead of HSV

    // Each letter represents a pair of four bits:
    // LVVSSHHF | (is_gbuffers << 3)
    return hsv_int.x | (hsv_int.y << 8u) | (hsv_int.z << 16u) | (uint(value.w * 15.0) << 24u);
}

VoxelInfo decode_voxel_info(uint value) {
    if (bool(value & 0x1000000u)) {
        VoxelInfo info;

        // _______1-________-__PPPPPP-FFFFGT_L
        info.is_light = bool(value & 1u);
        info.passability_mask = int((value >> 8u) & 63u);
        info.is_passable = bool(info.passability_mask);
        info.tints_light = bool(value & 4u);
        info.is_gbuffers = bool(value & 8u);
        info.timestamp = int((value >> 4u) & 0xFu);

        return info;
    } else {
        return VoxelInfo(false, true, false, false, 256, 63);
    }
}

uint encode_voxel_info(VoxelInfo info) {
    // _______1-________-__PPPPPP-FFFFGT_L
    return 0x1000000u | uint(info.is_light) | (uint(info.passability_mask) << 8u) | (uint(info.tints_light) << 2u) | (uint(info.is_gbuffers) << 3u) | ((uint(info.timestamp) & 0x0Fu) << 4u);
}

#endif