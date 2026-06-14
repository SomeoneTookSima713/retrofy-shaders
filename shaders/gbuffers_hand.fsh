#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex5;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform int currentRenderedItemId;

uniform ivec2 atlasSize;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in vec3 normal;
flat in int item_id;

flat in float glint_mask_mult;

/* RENDERTARGETS: 4,6,9 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 colortex6;
layout(location = 2) out vec4 out_colortex9;

void main() {
	colortex0 = texture(gtexture, texcoord) * color;
	colortex6 = colortex0;

	// colortex0.rgb *= get_static_light(lmcoord, worldTime, ambientLight, fogColor, blocklight_color);
	vec2 texel_offset;
	vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);

	#ifdef DO_COLORED_LIGHTING
        pixelated_lmcoord.x = texel_snap(blocklight.a, texel_offset);
		vec3 final_blocklight = colored_lighting_get_blocklight(pixelated_lmcoord, texel_offset);
	#else
		vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(pixelated_lmcoord.x, 1.2);
	#endif

	// #ifdef DITHER_LIGHTING
	// 	colortex0.rgb *= hsv_posterize_dithered(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
	// #else
		colortex0.rgb *= hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	// #endif
	colortex0.rgb *= get_normal_based_tint(normal, lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime);
	out_colortex9 = vec4(0.0, 0.0, 0.0, 0.0);

	if (currentRenderedItemId == 69) { // Items excluded from enchantment glint outlines
		// out_colortex5 = vec4(1.0, 0.5, 1.0, 1.0);
		out_colortex9 = vec4(1.0, 1.0, 0.0, 1.0);
	}
	// if (item_id == 70) {
	// 	discard;
	// }

	if ((colortex0.a < 0.9 && item_id != 70) || (colortex0.a < 0.1 && item_id == 70)) {
		discard;
	}
}