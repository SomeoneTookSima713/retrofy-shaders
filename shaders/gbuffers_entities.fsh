#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/lib/ids.glsl"
#include "/lib/colors.glsl"
#include "/lib/dh_interp.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/lib/pixelation.glsl"

#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform vec4 entityColor;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform int entityId;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in vec4 normal;
// in vec3 tangent;
// in vec3 bitangent;
in float far_plane_distance;

#ifdef RENDER_LMCOORD
/* RENDERTARGETS: 0,1,7,6 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
layout(location = 2) out vec4 colortex6;
#else
/* RENDERTARGETS: 0,7,6 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
layout(location = 2) out vec4 colortex6;
#endif

void main() {
	colortex0 = texture(gtexture, texcoord) * color;
	colortex6 = colortex0;
	colortex0.rgb = mix(colortex0.rgb, entityColor.rgb, entityColor.a);

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
	colortex0.rgb *= mix(1.0, get_normal_based_tint(normal.xyz, lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime), normal.a);

	if (colortex0.a < alphaTestRef || should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
		discard;
	}

	if (entityId == ID_ENTITY_GHAST) {
		colortex0.rgb = hsv2rgb(rgb2hsv(colortex0.rgb) * vec3(1.0, 0.5, 1.2));
		colortex0.a = 0.8;
	}

	// colortex0.rgb = vec3(colortex0.a, 0.0, 0.0);

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal.xyz * 0.5 + 0.5, 1.0);
}