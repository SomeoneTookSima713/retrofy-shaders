#version 430 compatibility

// Clears out the old elements of voxel_img

#include "/effects/options.glsl"
#include "/lib/voxelization_encoding.glsl"

#ifndef CLH_UNIFORM_VOXEL_IMG
    #define CLH_UNIFORM_VOXEL_IMG
    layout (r32ui) uniform uimage3D voxel_img;
    layout (rgba8) uniform image3D color_img;
    layout (rgba8) uniform image3D color_img_flip;
#endif

const ivec3 workGroups = ivec3(VOXEL_WORKGROUP_COUNT, VOXEL_WORKGROUP_COUNT, VOXEL_WORKGROUP_COUNT);

#if LIGHT_PROPAGATION_WORKGROUP_SIZE == 4
    layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;
#elif LIGHT_PROPAGATION_WORKGROUP_SIZE == 8
    layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
#endif

uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

uniform int frameCounter;

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
    // ivec3 camshift = cameraPositionInt - previousCameraPositionInt;
    
    uvec2 payload = load_voxel_payload(voxel_pos_base);
    // vec4 color = imageLoad(color_img, voxel_pos_base);
    // vec4 color_flip = imageLoad(color_img_flip, voxel_pos_base);

    // memoryBarrierImage();

    if (!light_is_from_current_frame(decode_voxel_info(payload.y), frameCounter)) {
        store_voxel_payload(voxel_pos_base, uvec4(0u));
    }
    // store_voxel_payload(voxel_pos_base - camshift, light_is_from_current_frame(decode_voxel_info(payload.y), frameCounter) ? uvec4(payload, uvec2(0)) : uvec4(0u));
    // imageStore(color_img, voxel_pos_base - camshift, color);
    // imageStore(color_img_flip, voxel_pos_base - camshift, color_flip);
    #endif
}