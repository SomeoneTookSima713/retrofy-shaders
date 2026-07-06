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

bool colored_lighting_block_is_passable(float block_alpha, int block_id, vec2 uv, vec4 at_midBlock, vec2 midTexCoord, vec3 normal, vec2 atlas_size) {
    vec2 quad_pixels = 2.0 * atlas_size * abs(uv - midTexCoord);

    return block_id != 1000 && (
        block_alpha < 0.95
     || block_id == 202
     || clamp(block_id, 1001, 1063) == block_id
     || quad_pixels.x < 15.9
     || quad_pixels.y < 15.9
     || dot(at_midBlock.xyz / 64.0, normal) > -0.4
    );
}

#ifndef MATH_SUM_FUNC
#define MATH_SUM_FUNC
    uint sum(uvec3 val) {
        return val.x + val.y + val.z;
    }
#endif

void colored_lighting_voxelize_terrain(
    vec3 relative_block_center,
    vec2 mc_Entity,
    vec4 at_midBlock,
    vec2 midTexCoord,
    vec2 texcoord,
    vec3 tangent,
    vec3 bitangent,
    vec3 normal,
    bool is_sable_contraption,
    bool is_gbuffers,
    sampler2D gtexture,
    ivec2 atlasSize,
    int frameCounter,
    out int dbg_did_voxelize,
    out int dbg_passable,
    out int dbg_passability_mask,
    out int dbg_passability_mask_pos,
    out int dbg_overwrote_value
) {
    #ifdef DO_COLORED_LIGHTING
        ivec3 voxel_pos = ivec3(relative_block_center + VOXEL_AREA_RADIUS);
        vec2 atlas_size_float = vec2(atlasSize);

        int block_id = int(mc_Entity.x);
        bool has_custom_light_col = clamp(block_id, 100, 199) == block_id;
        // bool single_corner_check = has_custom_light_col || all(lessThan(at_midBlock.xyz, vec3(0.0)));

        #ifdef DEBUG_COLORED_LIGHTING
            dbg_did_voxelize = 0;
        #endif

        #ifndef DEBUG_COLORED_LIGHTING
            #define GBUFFERS_COND && (!is_gbuffers || max(abs(relative_block_center.x), max(abs(relative_block_center.y), abs(relative_block_center.z))) >= 16.0)
        #else
            #define GBUFFERS_COND 
            #define GBUFFERS_COND_ALT (!is_gbuffers || max(abs(relative_block_center.x), max(abs(relative_block_center.y), abs(relative_block_center.z))) >= 16.0)
        #endif
        if (!is_sable_contraption GBUFFERS_COND) {
            float midBlock_dot_normal = dot(at_midBlock.xyz, normal);
            #ifdef DEBUG_COLORED_LIGHTING
                dbg_did_voxelize = 1;
            #endif
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
            bool is_tinting_block = mc_Entity.x == 200.0;
            
            vec3 abs_normal = abs(normal);
            int comp_ind = (abs_normal.x > abs_normal.y) ? ((abs_normal.x > abs_normal.z) ? 0 : 2) : ((abs_normal.y > abs_normal.z) ? 1 : 2);
            uint passability_mask_pos = (clamp(block_id, 1000, 1063) == block_id || is_tinting_block/* || is_gbuffers */) ? VE_PASSABILITY_ALL : (uint(1<<(2*comp_ind)) * uint(normal[comp_ind] < 0.0 ? 2 : 1));
            
            bool passable = is_light_source || is_tinting_block || colored_lighting_block_is_passable(block_alpha, block_id, texcoord, at_midBlock, midTexCoord, normal, atlas_size_float);
            int passability_mask = clamp(block_id, 1000, 1063) == block_id ? block_id - 1000 : VE_PASSABILITY_ALL;
            if (midBlock_dot_normal > -0.4) {
                vec2 quad_pixels = 2.0 * atlas_size_float * abs(texcoord - midTexCoord);

                ivec3 at_midBlock_signage = ivec3(notEqual(at_midBlock.xyz, vec3(0.0))) * ivec3(sign(at_midBlock.xyz) * 0.5 + 1.51);
                // // passability_mask_pos |= 63u ^ uint(3 << (2*comp_ind));
                // passability_mask_pos |= at_midBlock_signage.x + at_midBlock_signage.y << 1 + at_midBlock_signage.z << 2;

                passability_mask_pos = (quad_pixels.x >= 15.5 && quad_pixels.y >= 15.5)
                    ? 63u ^ ((findLSB(passability_mask_pos) & 1) == 0 ? passability_mask_pos << 1u : passability_mask_pos >> 1u)
                    : passability_mask_pos | uint(at_midBlock_signage.x | at_midBlock_signage.y << 2 | at_midBlock_signage.z << 4);
                    // : passability_mask_pos | sum(
                    //     mix(uvec3(VE_PASSABILITY_NEGX, VE_PASSABILITY_NEGY, VE_PASSABILITY_NEGZ), uvec3(0), neg_dirs) |
                    //     mix(uvec3(VE_PASSABILITY_POSX, VE_PASSABILITY_POSY, VE_PASSABILITY_POSZ), uvec3(0), pos_dirs)
                    // );
            }

            #ifndef DEBUG_COLORED_LIGHTING
                if (is_tinting_block || is_gbuffers) {
                    passability_mask_pos = passable ? 63u : 0u;
                }
            #else
                if (is_tinting_block || (is_gbuffers && max(abs(relative_block_center.x), max(abs(relative_block_center.y), abs(relative_block_center.z))) >= 16.0)) {
                    passability_mask_pos = passable ? 63u : 0u;
                }
                dbg_passability_mask = passability_mask;
                dbg_passability_mask_pos = int(passability_mask_pos);
            #endif

            uvec4 payload = uvec4(
                (is_light_source || is_tinting_block) ? encode_color_and_light_voxel(vec4(light_color, is_light_source ? at_midBlock.w/15.0 : 1.0)) : 0,
                encode_voxel_info(VoxelInfo(is_light_source, passable, is_tinting_block, is_gbuffers, frameCounter + (is_gbuffers ? 1 : 0), passable ? passability_mask : VE_PASSABILITY_NONE)),
                0,
                0
            );

            #ifdef DEBUG_COLORED_LIGHTING
            if (GBUFFERS_COND_ALT) {
            #endif
                imageStore(voxel_img, voxel_pos, payload.xzzz);
                
                // Only replaces empty values with the current data, otherwise only amends it using the if statement below
                // The zeroing of old data happens in begin_b.csh
                uint curr_val = imageAtomicCompSwap(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), 0u, payload.y);
                // if (((payload.y ^ curr_val) & ~(VE_VOXELINFO_SHIFT_PASSABILITY)) != 0u) {
                //     imageAtomicCompSwap(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), curr_val, payload.y);
                // }
                if (passable || is_gbuffers) {
                    imageAtomicOr(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), passability_mask_pos << VE_VOXELINFO_SHIFT_PASSABILITY);
                    // curr_val |= passability_mask_pos << VE_VOXELINFO_SHIFT_PASSABILITY;
                } else /* if (!is_gbuffers) */ {
                    imageAtomicAnd(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), ~(passability_mask_pos<<VE_VOXELINFO_SHIFT_PASSABILITY));
                    // curr_val &= ~(passability_mask_pos<<VE_VOXELINFO_SHIFT_PASSABILITY);
                }
            #ifdef DEBUG_COLORED_LIGHTING
            }
            #endif
            // uint new_val = is_same_block ? (curr_val | (payload.y & ((~VE_VOXELINFO_PASSABILITY) | (passability_mask_pos << VE_VOXELINFO_SHIFT_PASSABILITY)))) : payload.y;
            // bool overwrote_value;
            // if ((payload.y & (~VE_VOXELINFO_PASSABILITY)) != (curr_val & (~VE_VOXELINFO_PASSABILITY))) {
            //     overwrote_value = true;
            //     if (imageAtomicCompSwap(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), curr_val, payload.y) != curr_val) {
            //         overwrote_value = false;
            //         if (passable) {
            //             imageAtomicOr(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), passability_mask_pos << VE_VOXELINFO_SHIFT_PASSABILITY);
            //         } else {
            //             imageAtomicAnd(voxel_img, voxel_pos+ivec3(0,VOXEL_AREA_SIZE,0), ~(passability_mask_pos<<VE_VOXELINFO_SHIFT_PASSABILITY));
            //         }
            //     }
            // }
            #ifdef DEBUG_COLORED_LIGHTING
                dbg_passable = int(passable);
                // dbg_passability_mask = passability_mask;
                // dbg_passability_mask_pos = int(passability_mask_pos);
                // dbg_overwrote_value = int(overwrote_value);
                dbg_overwrote_value = int(dot(at_midBlock.xyz, normal) > -0.4);
            #endif
        }
    #endif
}

void colored_lighting_voxelize_terrain(
    vec3 relative_block_center,
    vec2 mc_Entity,
    vec4 at_midBlock,
    vec2 midTexCoord,
    vec2 texcoord,
    vec3 tangent,
    vec3 bitangent,
    vec3 normal,
    bool is_sable_contraption,
    bool is_gbuffers,
    sampler2D gtexture,
    ivec2 atlasSize,
    int frameCounter
) {
    int u1, u2, u3, u4, u5;
    colored_lighting_voxelize_terrain(
        relative_block_center,
        mc_Entity,
        at_midBlock,
        midTexCoord,
        texcoord,
        tangent,
        bitangent,
        normal,
        is_sable_contraption,
        is_gbuffers,
        gtexture,
        atlasSize,
        frameCounter,
        u1, u2, u3, u4, u5
    );
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