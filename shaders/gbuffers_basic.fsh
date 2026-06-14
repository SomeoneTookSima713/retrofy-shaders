#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;

uniform int worldTime;
uniform float ambientLight;
uniform vec3 fogColor;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
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
	// colortex0 = color * vec4(get_static_light(lmcoord, worldTime, ambientLight, fogColor, blocklight_color), 1.0);
	colortex0 = color;

	#ifdef DO_COLORED_LIGHTING
        vec2 new_lmcoord = vec2(blocklight.a, lmcoord.y);
		vec3 final_blocklight = colored_lighting_get_blocklight(new_lmcoord, vec2(0.0));
	#else
        vec2 new_lmcoord = lmcoord;
		vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(new_lmcoord.x, 1.2);
	#endif
	
	// #ifdef DITHER_LIGHTING
	// 	colortex0.rgb *= hsv_posterize_dithered(get_static_light(lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
	// #else
		colortex0.rgb *= hsv_posterize(get_static_light(new_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	// #endif
	if (colortex0.a < alphaTestRef) {
		discard;
	}

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(new_lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);

}