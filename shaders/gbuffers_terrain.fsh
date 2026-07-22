#version 430 compatibility

#include "/lib/pixelation.glsl"
#include "/effects/options.glsl"
#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/lib/dh_interp.glsl"
#include "/lib/voxelization_encoding.glsl"
#include "/lib/lod_utils.glsl"

#include "/effects/colored_lighting/fragment.glsl"

// For debugging
#ifdef DEBUG_COLORED_LIGHTING
    layout(r32ui) uniform uimage3D voxel_img;
    layout(rgba8) uniform image3D color_img;
    layout(rgba8) uniform image3D color_img_flip;
    uniform usampler3D voxel_img_sampler;
    uniform sampler3D color_img_sampler;
    uniform sampler3D color_img_flip_sampler;

    #define CLH_READ_COLOR(read_pos) (((frameCounter & 1) == 0) ? imageLoad(color_img, read_pos) : imageLoad(color_img_flip, read_pos))
    #define CLH_SAMPLE_COLOR(read_pos) (((frameCounter & 1) == 0) ? texture3D(color_img_sampler, read_pos) : texture3D(color_img_flip_sampler, read_pos))
#endif

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex8;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform vec3 cameraPositionFract;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;

#ifdef LODS_ENABLED
uniform mat4 LOD_PROJ_INV;
uniform sampler2D LOD_DEPTHTEX_FULL;
#endif

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec3 color;
in float ao;
in vec3 normal;
in vec3 tangent;
// in vec3 bitangent;
in float normal_influence;
flat in int is_sable;
in float lod_depth;

#ifdef DISTANT_HORIZONS 
	in float far_plane_distance;
#endif

#ifdef DEBUG_COLORED_LIGHTING
    in vec3 frag_at_midBlock;
    flat in int dbg_did_voxelize;
    flat in int dbg_overwrote_value;
    flat in int dbg_passable;
    flat in int dbg_passability_mask;
    flat in int dbg_passability_mask_pos;
#endif

// #ifdef DITHER_LIGHTING
// 	in vec2 surface_tangent_world_pos;
// #endif

#ifdef RENDER_LMCOORD
/* RENDERTARGETS: 0,1,7,8 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
layout(location = 3) out vec4 lod_mask_stuff;
#else
/* RENDERTARGETS: 0,7,8 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
layout(location = 2) out vec4 lod_mask_stuff;
#endif

void main() {
    #ifdef LODS_ENABLED
    if (bool(is_sable) && geometry_is_behind_lods(gl_FragCoord.xy / vec2(viewWidth, viewHeight), LOD_DEPTHTEX_FULL, gl_FragCoord.z, gbufferProjection, LOD_PROJ_INV)) {
        discard;
    }
    #endif

	colortex0 = texture(gtexture, texcoord) * vec4(color, 1.0);

	vec2 texel_offset; // Gets set by pixelate_lmcoord()
	vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);
	colortex0.rgb *= texel_snap(ao, texel_offset);

	#ifdef DO_COLORED_LIGHTING
        pixelated_lmcoord.x = texel_snap(blocklight.a, texel_offset);
		vec3 final_blocklight = colored_lighting_get_blocklight(pixelated_lmcoord, texel_offset);
	#else
		vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(pixelated_lmcoord.x, 1.2);
	#endif
	
	#ifdef DITHER_LIGHTING
		colortex0.rgb *= hsv_posterize_dithered(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
	#else
		colortex0.rgb *= hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	#endif
	colortex0.rgb *= mix(1.0, get_normal_based_tint(normal, pixelated_lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime), normal_influence);

    #ifdef LODS_ENABLED
    lod_mask_stuff = vec4(0.0);
    #endif

    // colortex0.rgb = vec3(ao);

	#ifdef DEBUG_COLORED_LIGHTING
        vec4 world_pos_w = gbufferModelViewInverse * gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);
        vec3 world_pos = world_pos_w.xyz / world_pos_w.w;
        vec3 voxel_pos_float = block_centered_relative_pos + float(VOXEL_AREA_RADIUS);
        ivec3 voxel_pos_int = ivec3(block_centered_relative_pos + VOXEL_AREA_RADIUS);
		#ifdef DEBUG_CL_FLOODFILL_COLOR
            // colortex0.rgb = (CLH_SAMPLE_COLOR((world_pos + cameraPositionFract + float(VOXEL_AREA_RADIUS))/float(VOXEL_AREA_SIZE))).rgb;
            colortex0.rgb = (CLH_READ_COLOR(ivec3(voxel_pos_float + normal))).rgb;
        #endif
        #if defined DEBUG_CL_VOXEL_COLOR || defined DEBUG_CL_VOXEL_INFO
            uint voxel_color_payload = imageLoad(voxel_img, voxel_pos_int).r;
            uint voxel_info_payload = imageLoad(voxel_img, voxel_pos_int + ivec3(0, VOXEL_AREA_SIZE, 0)).r;
            vec4 voxel_color = decode_color_and_light(voxel_color_payload);
            VoxelInfo voxel_info = decode_voxel_info(voxel_info_payload);
        #endif

        #ifdef DEBUG_CL_VOXEL_COLOR
            if (!voxel_info_is_empty(voxel_info) && voxel_info.is_light) {
                colortex0.rgb = voxel_color.rgb;
            }
        #endif
        #ifdef DEBUG_CL_VOXEL_INFO
            #ifdef DEBUG_CL_VOXEL_INFO
                #define DBG_CLVI_DISPCOND (!voxel_info.is_light || frag_at_midBlock.x > 0.0)
            #else
                #define DBG_CLVI_DISPCOND true
            #endif

            if (!voxel_info_is_empty(voxel_info) && DBG_CLVI_DISPCOND) {
                #if DEBUG_CL_VOXEL_INFO_MODE == 0
                    vec3[] colors = vec3[](
                        voxel_info.is_passable ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.tints_light ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.is_gbuffers ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 3.0), 0, 2)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 1
                    vec3[] colors = vec3[](
                        vec3(1.0, 0.5, 0.0) * float(voxel_info.passability_mask & 1),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 2) >> 1),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 4) >> 2),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 8) >> 3),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 16) >> 4),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 32) >> 5)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 6.0), 0, 5)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 2
                    vec3[] colors = vec3[](
                        voxel_info.is_passable ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.tints_light ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.is_gbuffers ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0),
                        vec3(1.0, 0.5, 0.0) * float(voxel_info.passability_mask & 1),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 2) >> 1),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 4) >> 2),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 8) >> 3),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 16) >> 4),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 32) >> 5),
                        vec3(1.0, 0.0, 1.0) * float(voxel_info.timestamp) / 16.0
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 10.0), 0, 9)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 3
                    vec3[] colors = vec3[](
                        vec3(0.5),
                        bool(dbg_did_voxelize) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passable) ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_overwrote_value) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 1) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 2) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 4) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 8) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 16) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 32) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 1) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 2) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 4) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 8) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 16) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 32) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 16.0), 0, 15)];
                #endif
            }
        #endif
	#endif

    // colortex0.rgb = color;

	#ifdef DISTANT_HORIZONS
	if (colortex0.a < alphaTestRef || should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
	#else
	if (colortex0.a < alphaTestRef) {
	#endif
		discard;
	}
	// if (colortex0.a < alphaTestRef) {
	// 	discard;
	// }

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);
}