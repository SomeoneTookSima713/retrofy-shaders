#version 430 compatibility

#define FX_PIXELATED_LIGHTING_EXTRA_CHECKS
#include "/effects/pixelated_lighting.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/lib/pixelation.glsl"
#include "/lib/dh_interp.glsl"
#include "/lib/unified_depth.glsl"

#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D dhDepthTex0;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;

uniform float eyeAltitude;

uniform float sunAngle;

uniform float wetness;
uniform float rainStrength;
uniform float thunderStrength;

uniform bool isEyeInWater;

uniform ivec2 eyeBrightness;

uniform ivec3 cameraPositionInt;
uniform vec3 cameraPosition;

uniform float viewWidth;
uniform float viewHeight;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

in vec2 texcoord;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;
in float far_plane_distance;

/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;

#ifndef IS_IRIS
#define clrwl_computeFragment
#endif

void main() {
	vec2 lmcoord;
	float ao;
	vec4 overlayColor;

	clrwl_computeFragment(texture(gtexture, texcoord), colortex0, lmcoord, ao, overlayColor);

	// if (should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
	// 	discard;
	// }

	// vec4 view_w = gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight)* 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);
	// vec3 relative_pos = (gbufferModelViewInverse * vec4(view_w.xyz / view_w.z, 1.0)).xyz + cameraPositionFract + VOXEL_AREA_RADIUS;

    #ifdef DO_COLORED_LIGHTING
        lmcoord.x = blocklight.a;
    #endif

	vec2 texel_offset;// = compute_texel_offset(gtexture, texcoord, 1.0);
	vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);

	// colortex0.rgb = colortex0.rgb / ao * texel_snap(ao, texel_offset);

	colortex0.rgb = mix(colortex0.rgb, overlayColor.rgb, overlayColor.a);

	#ifdef DO_COLORED_LIGHTING
		vec3 final_blocklight = colored_lighting_get_blocklight(pixelated_lmcoord, texel_offset);
	#else
		vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(pixelated_lmcoord.x, 1.2);
	#endif

	// #ifdef DITHER_LIGHTING
	// 	colortex0.rgb *= hsv_posterize_dithered(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
	// #else
		colortex0.rgb *= hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	// #endif
	colortex0.rgb *= get_normal_based_tint(normal, 1.0, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime);

	vec2 view_size = vec2(viewWidth, viewHeight);
	vec3 viewspace = unidepth_get_viewspace_position(gl_FragCoord.xy/view_size, gl_FragCoord.z, texture(dhDepthTex0, gl_FragCoord.xy/view_size).r, gbufferProjectionInverse, dhProjectionInverse);
	// vec4 view_w = gbufferProjectionInverse * vec4((gl_FragCoord.xy / view_size * 2.0 + 1.0, gl_FragCoord.z * 2.0 + 1.0, 1.0));
	// vec3 viewspace = view_w.xyz / view_w.w;

	vec4 fog_col = get_fog_color(
		gl_FragCoord.xy/view_size, viewspace,
		eyeAltitude,
		FogMats(
			gbufferModelView, gbufferModelViewInverse,
			gbufferProjection, gbufferProjectionInverse,
			dhProjectionInverse
		),
		skyColor, fogColor,
		sunPosition, moonPosition,
        eyeBrightness,
		DEFAULT_FOG_PARAMS
	);
	colortex0.rgb = mix(colortex0.rgb, fog_col.rgb, fog_col.a);

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	
}