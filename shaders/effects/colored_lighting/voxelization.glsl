#ifndef FX_CLH_VOXELIZE
#define FX_CLH_VOXELIZE

#include "/effects/options.glsl"
#include "/lib/voxelization_encoding.glsl"
#ifdef VOXELIZE_ENTITIES
    #include "/lib/colored_lighting/entity_bins.glsl"
#endif

#ifndef CLH_UNIFORM_VOXEL_IMG
    #define CLH_UNIFORM_VOXEL_IMG
    layout (r32ui) uniform uimage3D voxel_img;
#endif

const vec3 custom_colored_lights[] = CUSTOM_COLORED_LIGHTS;

bool colored_lighting_block_is_passable(float block_alpha, int block_id, vec2 uv, vec2 midTexCoord, vec2 atlas_size) {
    vec2 quad_pixels = 2.0 * atlas_size * abs(uv - midTexCoord);

    return block_alpha < 0.95 || block_id == 202 || clamp(block_id, 1000, 1063) == block_id || quad_pixels.x < 15.9 || quad_pixels.y < 15.9;
}

void colored_lighting_voxelize_terrain(
    vec3 relative_block_center,
    vec2 mc_Entity,
    vec4 at_midBlock,
    vec2 midTexCoord,
    vec2 texcoord,
    vec3 normal,
    bool is_sable_contraption,
    bool is_gbuffers,
    sampler2D gtexture,
    ivec2 atlasSize,
    int frameCounter
) {
    #ifdef DO_COLORED_LIGHTING
        ivec3 voxel_pos = ivec3(relative_block_center + VOXEL_AREA_RADIUS);
        vec2 atlas_size_float = vec2(atlasSize);

        int block_id = int(mc_Entity.x);
        bool has_custom_light_col = clamp(block_id, 100, 199) == block_id;
        // bool single_corner_check = has_custom_light_col || all(lessThan(at_midBlock.xyz, vec3(0.0)));

        #ifdef FULL_SHADOW_PASS
            #define GBUFFERS_VOXELIZATION_COND
        #else
            #define GBUFFERS_VOXELIZATION_COND && clamp(voxel_pos, 16, VOXEL_AREA_SIZE) == voxel_pos
        #endif

        if ((gl_VertexID & 3) == 0 && !is_sable_contraption GBUFFERS_VOXELIZATION_COND) {
            vec3 light_color;
            float block_alpha;

            if (has_custom_light_col) {
                light_color = custom_colored_lights[int(mc_Entity.x - 100.0)];
                block_alpha = 1.0;
                // light_color = vec3(mod(mc_Entity.x - 1000.0, 2.0)*0.5, mod(floor((mc_Entity.x - 1000.0)*0.5), 2.0)*0.5, mod(floor((mc_Entity.x - 1000.0)*0.25), 2.0)*0.5);
            } else {
                vec4 tex_sampled = textureLod(gtexture, texcoord, log2(atlas_size_float.x));
                light_color = tex_sampled.rgb * gl_Color.rgb;
                block_alpha = tex_sampled.a;
            }

            bool is_light_source = at_midBlock.w > 0.0 && mc_Entity.x != 201.0;
            bool is_tinting_block = at_midBlock.w == 0.0 && mc_Entity.x == 200.0;
            bool passable = is_light_source || is_tinting_block || colored_lighting_block_is_passable(block_alpha, block_id, texcoord, midTexCoord, atlas_size_float);
            int passability_mask = clamp(block_id, 1000, 1063) == block_id ? block_id - 1000 : VE_PASSABILITY_ALL;

            // // ivec3 pmp_tmp = ivec3(-normal * 0.5 + 1.5);
            // // int passability_mask_pos = (pmp_tmp.x) + (pmp_tmp.y << 2) + (pmp_tmp.z << 4);
            // int passability_mask_pos = int(dot(-normalize(normal) * 0.5 + 1.5, vec3(1.0, 4.0, 16.0)));
            // int passability_mask = is_light_source || is_tinting_block || colored_lighting_block_is_passable(block_alpha, block_id, texcoord, midTexCoord, atlas_size_float) ? passability_mask_pos : 0;
            // bool passable = bool(passability_mask);


            int timestamp_val = frameCounter + (is_gbuffers ? 1 : 0);

            uvec4 payload = uvec4(
                (is_light_source || is_tinting_block) ? encode_color_and_light_voxel(vec4(light_color, is_light_source ? at_midBlock.w/15.0 : 1.0)) : 0,
                encode_voxel_info(VoxelInfo(is_light_source, passable, is_tinting_block, is_gbuffers, timestamp_val, passable ? passability_mask : VE_PASSABILITY_NONE)),
                0,
                0
            );
            imageStore(voxel_img, voxel_pos, payload.xzzz);
            
            // OR's the passability flag (if the current value is of the same block) and replaces everything else
            uint curr_val = imageAtomicExchange(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), payload.y);
            imageAtomicOr(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), (payload.y & (~VE_VOXELINFO_PASSABILITY)) == (curr_val & (~VE_VOXELINFO_PASSABILITY)) ? (curr_val & VE_VOXELINFO_PASSABILITY) : 0);
        }
    #endif
}

#ifdef VOXELIZE_ENTITIES
    void colored_lighting_voxelize_entities(vec3 world_vert_pos, vec2 texcoord, vec2 midTexCoord, int currentRenderedItemId, sampler2D gtexture, ivec2 atlasSize, int frameCounter) {
        #ifdef DO_COLORED_LIGHTING
            ivec3 bin_pos = ivec3(world_vert_pos / 16.0 + float(cleb_rel_to_abs_offset));
            if (
                textureSize(gtexture, 0) == atlasSize
                && clamp(currentRenderedItemId, 100, 199) == currentRenderedItemId
                && all(lessThan((midTexCoord - texcoord)*vec2(atlasSize), vec2(-7.5)))
            ) {
                colored_lighting_add_entity_light(
                    colored_lighting_get_entity_bin(bin_pos),
                    fract(world_vert_pos / 16.0) * 16.0,
                    vec4(custom_colored_lights[currentRenderedItemId - 100], 1.0),
                    frameCounter
                );
            }
        #endif
    }
#endif

#endif