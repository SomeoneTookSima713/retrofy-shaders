#version 430 compatibility

// Actually computes the propagation of colored lights

#include "/effects/options.glsl"

const ivec3 workGroups = ivec3(VOXEL_WORKGROUP_COUNT, VOXEL_WORKGROUP_COUNT, VOXEL_WORKGROUP_COUNT);

#if LIGHT_PROPAGATION_WORKGROUP_SIZE == 4
    layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;
#elif LIGHT_PROPAGATION_WORKGROUP_SIZE == 8
    layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
#endif

layout (r32ui) uniform uimage3D voxel_img;
layout (rgba8) uniform image3D color_img;
layout (rgba8) uniform image3D color_img_flip;

uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

uniform int frameCounter;

#include "/lib/colors.glsl"
#include "/lib/voxelization_encoding.glsl"

vec4 read_color(ivec3 read_pos, ivec3 base_pos) {
    return ((frameCounter & 1) == 0) ? imageLoad(color_img_flip, read_pos) : imageLoad(color_img, read_pos);
}

void write_color(ivec3 pos, vec4 value) {
    if ((frameCounter & 1) == 0) {
        imageStore(color_img, pos, value);
    } else {
        imageStore(color_img_flip, pos, value);
    }
}

uvec2 load_voxel_payload(ivec3 pos) {
    return uvec2(imageLoad(voxel_img, pos).r, imageLoad(voxel_img, pos + ivec3(0, VOXEL_AREA_SIZE, 0)).r);
}

void store_voxel_payload(ivec3 pos, uvec4 data) {
    imageStore(voxel_img, pos, data.xzzz);
    imageStore(voxel_img, pos+ivec3(0,VOXEL_AREA_SIZE,0), data.yzzz);
}

void main() {
    #ifdef DO_COLORED_LIGHTING
    ivec3 voxel_pos_base = ivec3(gl_GlobalInvocationID);
    ivec3 camshift = cameraPositionInt - previousCameraPositionInt;

    ivec3 voxel_pos_read = voxel_pos_base + camshift;
    ivec3 voxel_pos_write = voxel_pos_base;
    
    vec4 curr_voxel_val;
    VoxelInfo curr_voxel_info;

    uvec2 shadow_voxel_payload = load_voxel_payload(voxel_pos_base);
    VoxelInfo shadow_voxel_info = decode_voxel_info(shadow_voxel_payload.g);
    bool shadow_is_new = light_is_from_current_frame(shadow_voxel_info, frameCounter);

    uvec2 gbuffers_voxel_payload = load_voxel_payload(voxel_pos_read);
    VoxelInfo gbuffers_voxel_info = decode_voxel_info(gbuffers_voxel_payload.g);
    bool gbuffers_is_new = light_is_from_current_frame(gbuffers_voxel_info, frameCounter);

    if (voxel_info_is_empty(gbuffers_voxel_info) || (!gbuffers_is_new && gbuffers_voxel_info.is_gbuffers)) {
        store_voxel_payload(voxel_pos_read, uvec4(0));
        gbuffers_voxel_info = VoxelInfo(false, false, false, false, 256, VE_PASSABILITY_NONE);
        gbuffers_is_new = false;
    }
    if (voxel_info_is_empty(shadow_voxel_info) || (!shadow_is_new && !shadow_voxel_info.is_gbuffers)) {
        store_voxel_payload(voxel_pos_base, uvec4(0));
        shadow_voxel_info = VoxelInfo(false, false, false, false, 256, VE_PASSABILITY_NONE);
        shadow_is_new = false;
    }

    if (voxel_info_is_empty(gbuffers_voxel_info) || !gbuffers_is_new || !gbuffers_voxel_info.is_gbuffers) {
        if (voxel_info_is_empty(shadow_voxel_info) || !shadow_is_new || shadow_voxel_info.is_gbuffers) {
            curr_voxel_val = vec4(0.0);
            curr_voxel_info = VoxelInfo(false, true, false, false, 256, VE_PASSABILITY_ALL);
        } else {
            curr_voxel_val = decode_color_and_light(shadow_voxel_payload.r);
            curr_voxel_info = shadow_voxel_info;
        }
    } else {
        curr_voxel_val = decode_color_and_light(gbuffers_voxel_payload.r);
        curr_voxel_info = gbuffers_voxel_info;
    }


    vec4 new_color_val;
    if (!curr_voxel_info.is_passable) {
        new_color_val = vec4(0.0);
    } else {
        vec4 vals[6] = vec4[](
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_POSX) ? read_color(voxel_pos_read + ivec3( 1, 0, 0), voxel_pos_base + ivec3( 1, 0, 0)) : vec4(0.0),
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_NEGX) ? read_color(voxel_pos_read + ivec3(-1, 0, 0), voxel_pos_base + ivec3(-1, 0, 0)) : vec4(0.0),
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_POSY) ? read_color(voxel_pos_read + ivec3( 0, 1, 0), voxel_pos_base + ivec3( 0, 1, 0)) : vec4(0.0),
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_NEGY) ? read_color(voxel_pos_read + ivec3( 0,-1, 0), voxel_pos_base + ivec3( 0,-1, 0)) : vec4(0.0),
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_POSZ) ? read_color(voxel_pos_read + ivec3( 0, 0, 1), voxel_pos_base + ivec3( 0, 0, 1)) : vec4(0.0),
            bool(curr_voxel_info.passability_mask & VE_PASSABILITY_NEGZ) ? read_color(voxel_pos_read + ivec3( 0, 0,-1), voxel_pos_base + ivec3( 0, 0,-1)) : vec4(0.0)
        );

        vec4 comp_max_val = curr_voxel_info.is_light ? curr_voxel_val : vec4(0.0);
        for (int i = 0; i < 6; i++) {
            comp_max_val = max(vec4(hsv2rgb(rgb2hsv(vals[i].rgb) - vec3(0.0, 0.0, 1.0/15.0)), vals[i].a - 1.0/15.0), comp_max_val);
        }

        new_color_val = comp_max_val;
        // if (curr_voxel_info.tints_light) {
        //     new_color_val.rgb = mix(new_color_val.rgb, curr_voxel_val.rgb, )
        // }
        new_color_val.rgb *= curr_voxel_info.tints_light ? curr_voxel_val.rgb : vec3(1.0);
    }

    write_color(voxel_pos_write, new_color_val);
    // write_color(voxel_pos_write, vec4(float(int(curr_voxel_info.is_light)), float(int(curr_voxel_info.is_passable)), 0.0, 1.0));

    // imageStore(color_img_flip, voxel_pos, uvec4(encode_color_and_light(new_color_val), 0, 0, 0));
    // imageStore(color_img, voxel_pos, imageLoad(voxel_img, voxel_pos));

    #endif
}