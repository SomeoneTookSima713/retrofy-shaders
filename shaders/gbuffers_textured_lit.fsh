#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;

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
	colortex0 = texture(gtexture, texcoord) * color;

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
	if (colortex0.a < alphaTestRef) {
		discard;
	}

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);
	
}