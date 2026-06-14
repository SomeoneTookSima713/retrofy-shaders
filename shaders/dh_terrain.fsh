#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/lib/dh_interp.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform float far;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec4 color;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;
in float far_plane_distance;
// in vec4 regular_viewspace_coord;
in float regular_clip_depth;
in float normal_influence;

#ifdef RENDER_LMCOORD
/* RENDERTARGETS: 0,1,7,8 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
layout(location = 3) out vec4 dh_stuff_mask;
#else
/* RENDERTARGETS: 0,7,8 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
layout(location = 2) out vec4 dh_stuff_mask;
#endif

void main() {
	colortex0 = color;
	// colortex0.rgb *= get_static_light(lmcoord, worldTime, ambientLight, fogColor, BLOCKLIGHT_COLOR);

	vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(lmcoord.x, 1.2);
	
	colortex0.rgb *= hsv_posterize(get_static_light(lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	colortex0.rgb *= mix(1.0, get_normal_based_tint(normal, lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime), normal_influence);

	// if (colortex0.a < alphaTestRef || !should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
	// 	discard;
	// }
	if (colortex0.a < alphaTestRef || far_plane_distance > far*0.25) {
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

	// dh_stuff_mask = vec4(0.0, 1.0, regular_viewspace_coord.z / regular_viewspace_coord.w * 0.5 + 0.5, 1.0);
	dh_stuff_mask = vec4(0.0, 1.0, regular_clip_depth, 1.0);
}