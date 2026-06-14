#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/effects/options.glsl"
#include "/effects/ssr.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/cam_utils.glsl"
#include "/lib/dh_interp.glsl"
#include "/lib/unified_depth.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex0;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float alphaTestRef = 0.1;

uniform float viewWidth;
uniform float viewHeight;

// Declared by cam_utils.glsl
// uniform vec3 cameraPositionFract;

uniform bool isEyeInWater;

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

uniform ivec2 eyeBrightness;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

uniform vec3 cameraPosition;

in vec2 lmcoord;
in vec4 color;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;
in float far_plane_distance;
// in vec4 regular_viewspace_coord;
in float regular_clip_depth;

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
	if (texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x < 1.0) {
		discard;
	}

	colortex0 = color;

	vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(lmcoord.x, 1.2);
	
	colortex0.rgb *= hsv_posterize(get_static_light(lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	colortex0.rgb *= get_normal_based_tint(normal, lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime);

	if (colortex0.a < alphaTestRef || !should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
		discard;
	}

	vec2 view_size = vec2(viewWidth, viewHeight);
	// vec3 viewspace = unidepth_get_viewspace_position(gl_FragCoord.xy/view_size, texture(depthtex0, gl_FragCoord.xy/view_size).r, gl_FragCoord.z, gbufferProjectionInverse, dhProjectionInverse);
	vec4 viewspace_w = dhProjectionInverse * vec4(gl_FragCoord.xy / view_size * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);
	vec3 viewspace = viewspace_w.xyz / viewspace_w.w;
	// float fog_amount = get_fog_amount(viewspace, eyeAltitude, gbufferModelViewInverse);

	// color.rgb = mix(color.rgb, calcSkyColor(normalize(screenToView(vec3(texcoord, 1.0), gbufferProjectionInverse)), gbufferModelView, skyColor, fogColor, sunPosition, moonPosition, FOG_SUN_COLOR, FOG_MOON_COLOR), fog_amount);
	// color.rgb = vec3(get_z_unified(texcoord, depthtex0, dhDepthTex0, gbufferProjectionInverse, dhProjectionInverse)*0.005, 0.0, 0.0);
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
		// FogPlanes(near, far, dhNearPlane, dhFarPlane)
	);
	colortex0.rgb = mix(colortex0.rgb, fog_col.rgb, fog_col.a);

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);

	// dh_water_mask = vec4(float(int(should_discard_with_blur(far_plane_distance, gl_FragCoord.xy))), 0.0, 0.0, 1.0);
	// dh_stuff_mask = vec4(1.0, 0.0, regular_viewspace_coord.z / regular_viewspace_coord.w * 0.5 + 0.5, 1.0);
	dh_stuff_mask = vec4(1.0, 0.0, regular_clip_depth, 1.0);
}