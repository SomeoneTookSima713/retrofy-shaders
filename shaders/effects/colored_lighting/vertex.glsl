#ifndef FX_CLH_VERTEX
#define FX_CLH_VERTEX

#ifdef CLH_SAFE_MODE
#define CLH_FOOTPOS_CALCULATE vec3 foot_pos = (gbufferModelViewInverse * vec4((gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0)).xyz, 1.0)).xyz
#define CLH_FOOTPOS_VALUE foot_pos
#else
#define CLH_FOOTPOS_CALCULATE
#define CLH_FOOTPOS_VALUE gl_Vertex.xyz
#endif

// Dependencies
#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/voxelization_encoding.glsl"
#include "/lib/colored_lighting/entity_bins.glsl"

// Uniforms
#ifndef CLH_UNIFORM_VOXEL_IMG
    #define CLH_UNIFORM_VOXEL_IMG
    layout (r32ui) uniform uimage3D voxel_img;
#endif

layout (rgba8) uniform image3D color_img;
layout (rgba8) uniform image3D color_img_flip;

uniform sampler3D color_img_sampler;
uniform sampler3D color_img_flip_sampler;

#ifdef CLH_SAFE_MODE
    uniform mat4 gbufferModelViewInverse;
#endif

// Vertex shader outputs
out vec3 block_centered_relative_pos;
out vec3 relative_pos;
out vec4 blocklight;

#ifdef DITHER_LIGHTING
#ifdef IMPL_DITHER
	out vec2 surface_tangent_world_pos;
#endif
#endif

// Functionality
#define CLH_READ_COLOR(read_pos) (((frameCounter & 1) == 0) ? imageLoad(color_img, read_pos) : imageLoad(color_img_flip, read_pos))
#define CLH_SAMPLE_COLOR(read_pos) (((frameCounter & 1) == 0) ? texture3D(color_img_sampler, read_pos) : texture3D(color_img_flip_sampler, read_pos))

vec4 colored_lighting_compute_entity_colored_lighting(vec3 relative_pos, vec3 previousCameraPositionFract, int frameCounter) {
    ivec4 bin_offsets = ivec4(ivec3(sign(fract(relative_pos / 16.0) - 0.5)), 0);

    ivec3 bin_pos_base = ivec3(relative_pos / 16.0 + float(cleb_rel_to_abs_offset));
    int[] bin_ids = int[](
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.www),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.xww),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.wyw),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.xyw),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.wwz),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.xwz),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.wyz),
        colored_lighting_get_entity_bin(bin_pos_base + bin_offsets.xyz)
    );

    vec4 color = vec4(0.0);

    for (int j = 0; j < 8; j++) {
        int bin_id = bin_ids[j];
        for (int i = 0; i < cl_entity_bins[bin_id].light_count; i++) {
            CLEntityLightDecoded light = colored_lighting_get_entity_light(bin_id, i);
            if (colored_lighting_light_is_current(light, frameCounter)) {
                vec3 rel_pos = light.position - relative_pos;
                float manhattan_dist = abs(rel_pos.x) + abs(rel_pos.y) + abs(rel_pos.z);
                
                float strength = clamp(light.color.a - manhattan_dist/8.0, 0.0, 1.0);
                color = max(color, vec4(light.color.rgb * strength, strength));
            }
        }
    }

    return clamp(color, vec4(vec3(AMBIENT_LIGHT_ADD), 0.0), vec4(1.0));
}

void colored_lighting_compute_vertex_outputs_terrain(vec4 at_midBlock, vec3 normal, vec3 cameraPositionFract, vec3 previousCameraPositionFract, int frameCounter) {
    CLH_FOOTPOS_CALCULATE;
    #ifndef CLH_MANUAL_POS_ATTRIBS
        block_centered_relative_pos = CLH_FOOTPOS_VALUE + at_midBlock.xyz/64.0 + cameraPositionFract;
        relative_pos = CLH_FOOTPOS_VALUE + cameraPositionFract + VOXEL_AREA_RADIUS;
    #endif

    #if ((defined DITHER_LIGHTING && defined IMPL_DITHER) || defined DO_COLORED_LIGHTING)
        // mat3x2 atmb_to_sc;
        // ivec3 world_sc_x;
        // ivec3 world_sc_y;
        // vec3 abs_normal = abs(normal);
        ivec3 abs_normal = ivec3(abs(normal) * 1.414);

        mat3x2 atmb_to_sc = mat3x2(
            abs_normal.z, abs_normal.y,
            abs_normal.x, abs_normal.z,
            abs_normal.y, abs_normal.x
        );

        ivec3 world_sc_x = abs_normal.zxy;
        ivec3 world_sc_y = abs_normal.yzx;
    #endif

    #ifdef DITHER_LIGHTING
        #ifdef IMPL_DITHER
            surface_tangent_world_pos = (distance(gl_Vertex.xyz, CLH_FOOTPOS_VALUE) > 0.01) ? vec2(0.0) : atmb_to_sc * ((CLH_FOOTPOS_VALUE + cameraPositionFract) * 16.0);
        #endif
    #endif

    #ifdef DO_COLORED_LIGHTING
        // TODO: Fix light leaking
        ivec3 voxel_pos_base = ivec3(block_centered_relative_pos + normal + VOXEL_AREA_RADIUS);

        vec2 surface_coords = atmb_to_sc * at_midBlock.xyz;
        ivec2 surf_signs = ivec2(sign(surface_coords));
        surface_coords = abs(surface_coords);
        
        vec4 sampled_values[4] = vec4[](
            CLH_READ_COLOR(voxel_pos_base),
            CLH_READ_COLOR(voxel_pos_base - world_sc_x * surf_signs.x),
            CLH_READ_COLOR(voxel_pos_base - world_sc_y * surf_signs.y),
            CLH_READ_COLOR(voxel_pos_base - world_sc_x * surf_signs.x - world_sc_y * surf_signs.y)
        );

        float total = 0.0;
        blocklight = vec4(0.0);
        for (int i = 0; i < 4; i++) {
            float weight = sampled_values[i].w * abs(float(i & 1) - surface_coords.x) * abs(float(i >> 1) - surface_coords.y);
            blocklight += sampled_values[i] * weight;
            total += weight;
        }

        blocklight /= max(total, 0.01);

        blocklight = max(blocklight, colored_lighting_compute_entity_colored_lighting(CLH_FOOTPOS_VALUE, previousCameraPositionFract, frameCounter));
    #endif
}

void colored_lighting_compute_vertex_outputs_general(vec3 normal, vec3 cameraPositionFract, vec3 previousCameraPositionFract, int frameCounter, out float emulated_lmcoord_x) {
    CLH_FOOTPOS_CALCULATE;
    #ifndef CLH_MANUAL_POS_ATTRIBS
        block_centered_relative_pos = CLH_FOOTPOS_VALUE + cameraPositionFract;
        relative_pos = CLH_FOOTPOS_VALUE + cameraPositionFract + VOXEL_AREA_RADIUS;
    #endif

    // // Dithering currently doesn't work on non-axis-aligned things (and doesn't look nice on moving things)
    #if (defined DITHER_LIGHTING && defined IMPL_DITHER)
        // mat3x2 atmb_to_sc;
        // ivec3 world_sc_x;
        // ivec3 world_sc_y;
        // vec3 abs_normal = abs(normal);
        ivec3 abs_normal = ivec3(abs(normal) * 1.414);

        mat3x2 atmb_to_sc = mat3x2(
            abs_normal.z, abs_normal.y,
            abs_normal.x, abs_normal.z,
            abs_normal.y, abs_normal.x
        );

        ivec3 world_sc_x = abs_normal.zxy;
        ivec3 world_sc_y = abs_normal.yzx;
    #endif

    #ifdef DITHER_LIGHTING
        #ifdef IMPL_DITHER
            #ifdef CLH_SAFE_MODE
            surface_tangent_world_pos = atmb_to_sc * ((foot_pos + cameraPositionFract) * 16.0);
            #else
            surface_tangent_world_pos = atmb_to_sc * ((gl_Vertex.xyz + cameraPositionFract) * 16.0);
            #endif
        #endif
    #endif

    #ifdef DO_COLORED_LIGHTING
        blocklight = CLH_SAMPLE_COLOR((relative_pos + 0.1*normal) / VOXEL_AREA_SIZE);
        blocklight = max(blocklight, colored_lighting_compute_entity_colored_lighting(CLH_FOOTPOS_VALUE, previousCameraPositionFract, frameCounter));
        emulated_lmcoord_x = clamp(blocklight.a, 1.0/32.0, 31.0/32.0);
    #endif
}

void colored_lighting_compute_vertex_outputs_general(vec3 normal, vec3 cameraPositionFract, vec3 previousCameraPositionFract, int frameCounter) {
    float unused;
    colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter, unused);
}

#endif