#version 430 compatibility

#include "/lib/pixelation.glsl"
#include "/effects/options.glsl"
#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/lib/dh_interp.glsl"
#include "/lib/voxelization_encoding.glsl"

#include "/effects/colored_lighting/fragment.glsl"

uniform usampler3D voxel_img_sampler;

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

// uniform int frameCounter; // Defined by the colored lighting helper

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec3 color;
in float ao;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;
in float normal_influence;

#ifdef DISTANT_HORIZONS 
	in float far_plane_distance;
#endif

// #ifdef DITHER_LIGHTING
// 	in vec2 surface_tangent_world_pos;
// #endif

#ifdef RENDER_LMCOORD
/* RENDERTARGETS: 0,1,7 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
#else
/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
#endif

void main() {
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

	#ifdef DO_COLORED_LIGHTING
		#if defined DEBUG_ONLY_DISPLAY_LIGHT_VOXELS || defined DEBUG_DISPLAY_VOXEL_INFO 
			#define VOXEL_DISPLAY_COND true
		#else
			#define VOXEL_DISPLAY_COND voxel_data.w > 0.0
		#endif
		// #define USED_POS snapped_rel_pos
		#define USED_POS texel_snap(relative_pos, compute_texel_offset(gtexture, texcoord, 1.0/16.0))
		// #define USED_POS floor(block_centered_relative_pos)

		#if defined DEBUG_DISPLAY_LIGHT_VOXELS && defined DEBUG_DISPLAY_LIGHT_VOXEL_STRENGTHS
			vec4 voxel_data = decode_color_and_light(texture3D(voxel_img_sampler, USED_POS/vec3(VOXEL_AREA_SIZE)).r);

			if (VOXEL_DISPLAY_COND) {
				colortex0.rgb = voxel_data.rgb * voxel_data.w;
			}
		#elif defined DEBUG_DISPLAY_LIGHT_VOXELS && defined DEBUG_DISPLAY_VOXEL_SOURCE
			uint voxel_data_src = texture3D(voxel_img_sampler, USED_POS/vec3(VOXEL_AREA_SIZE)).r;
			vec4 voxel_data = decode_color_and_light(voxel_data_src);
			bool voxel_is_gbuffers = light_is_from_gbuffers(voxel_data_src);
			
			vec3 block_center_relative = relative_pos - block_centered_relative_pos;

			if (VOXEL_DISPLAY_COND) {
				if (dot(block_center_relative, vec3(1, 1, 1)) > 0.0) {
					colortex0.rgb = vec3(float(int(voxel_is_gbuffers)));
				} else {
					colortex0.rgb = voxel_data.rgb * voxel_data.w;
				}
			}
		#elif defined DEBUG_DISPLAY_LIGHT_VOXELS
			uvec4 voxel_payload = texture3D(voxel_img_sampler, USED_POS/vec3(VOXEL_AREA_SIZE));
			VoxelInfo voxel_info = decode_voxel_info(voxel_payload.g);
			vec4 voxel_data = decode_color_and_light(voxel_payload.r);

			#undef VOXEL_DISPLAY_COND
			#define VOXEL_DISPLAY_COND voxel_data.w > 0.0 && light_is_from_current_frame(voxel_info, frameCounter) && voxel_info.is_light

			if (VOXEL_DISPLAY_COND) {
				colortex0.rgb = voxel_data.rgb;
			}
		#elif defined DEBUG_DISPLAY_LIGHT_VOXEL_STRENGTHS
			vec4 voxel_data = decode_color_and_light(texture3D(voxel_img_sampler, USED_POS/vec3(VOXEL_AREA_SIZE)).r);

			if (VOXEL_DISPLAY_COND) {
				colortex0.rgb = voxel_data.www;
			}
		#elif defined DEBUG_DISPLAY_VOXEL_INFO
			VoxelInfo voxel_info = decode_voxel_info(texture3D(voxel_img_sampler, (block_centered_relative_pos + VOXEL_AREA_RADIUS)/vec3(VOXEL_AREA_SIZE)).g);

			colortex0.rgb = vec3(float(int(voxel_info.is_light)), float(int(voxel_info.is_passable)), float(int(voxel_info.tints_light)));
		#endif

		#ifdef DEBUG_DISPLAY_FOODFILL
			vec4 floodfill_data;
			if ((frameCounter & 1) == 0) {
				floodfill_data = texture3D(color_img_sampler, texel_snap(relative_pos, compute_texel_offset(gtexture, texcoord, 1.0/16.0))/vec3(VOXEL_AREA_SIZE));
			} else {
				floodfill_data = texture3D(color_img_flip_sampler, texel_snap(relative_pos, compute_texel_offset(gtexture, texcoord, 1.0/16.0))/vec3(VOXEL_AREA_SIZE));
			}

			if (!(VOXEL_DISPLAY_COND)) {
				colortex0.rgb = floodfill_data.rgb;
			}
		#endif
		#ifdef DEBUG_DISPLAY_BLOCKLIGHT_COL
			colortex0.rgb = blocklight_color;
		#endif
	#endif

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