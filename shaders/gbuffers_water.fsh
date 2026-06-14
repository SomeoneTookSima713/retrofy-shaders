#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/effects/options.glsl"
#include "/effects/ssr.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/blur.glsl"
#include "/lib/dh_interp.glsl"
// #include "/lib/cam_utils.glsl"
#include "/lib/unified_depth.glsl"
#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex8;
uniform sampler2D depthtex0;

#if defined DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
    uniform mat4 dhProjectionInverse;
    #define LOD_DEPTHTEX dhDepthTex0
    #define LOD_INV_PROJ dhProjectionInverse
#elif defined VOXY
    uniform sampler2D vxDepthTexTrans;
    uniform mat4 vxProjInv;
    #define LOD_DEPTHTEX vxDepthTexTrans
    #define LOD_INV_PROJ vxProjInv
#else
    #define LOD_DEPTHTEX depthtex0
    #define LOD_DEPTHTEX_FULL depthtex0
    #define LOD_INV_PROJ gbufferProjectionInverse
#endif

uniform int worldTime;

uniform float viewWidth;
uniform float viewHeight;

uniform float ambientLight;
uniform vec3 skyColor;
uniform vec3 fogColor;

// Declared by cam_utils.glsl
// uniform vec3 cameraPositionFract;
uniform ivec3 cameraPositionInt;
uniform vec3 cameraPosition;

uniform ivec2 atlasSize;

uniform bool isEyeInWater;

uniform float alphaTestRef = 0.1;

uniform float near;
uniform float far;
uniform float dhNearPlane;
uniform float dhFarPlane;

// Declared by cam_utils.glsl
// uniform vec3 cameraPositionFract;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float eyeAltitude;

uniform float sunAngle;

uniform float wetness;
uniform float rainStrength;
uniform float thunderStrength;

uniform ivec2 eyeBrightness;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;
#ifdef DISTANT_HORIZONS
	in float far_plane_distance;
#endif

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
	vec2 view_size = vec2(viewWidth, viewHeight);

	colortex0 = texture(gtexture, texcoord) * color;

	vec2 texel_offset;
	vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);

	#ifdef DO_COLORED_LIGHTING
        pixelated_lmcoord.x = texel_snap(blocklight.a, texel_offset);
		vec3 final_blocklight = colored_lighting_get_blocklight(pixelated_lmcoord, texel_offset);
	#else
		vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(pixelated_lmcoord.x, 1.2);
	#endif

	// colortex0.rgb *= get_static_light(lmcoord, worldTime, ambientLight, fogColor, blocklight_color);
	
	#ifdef DITHER_LIGHTING
		colortex0.rgb *= hsv_posterize_dithered(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
	#else
		colortex0.rgb *= hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
	#endif
	// float depth_diff = get_view_position(gl_FragCoord.xy/view_size, texture(dhDepthTex0, gl_FragCoord.xy/view_size).r, dhProjectionInverse).z - get_view_position(gl_FragCoord.xy/view_size, gl_FragCoord.z, gbufferProjectionInverse).z;
	// float depth_diff = unidepth_linearize_depth(gl_FragCoord.z, near, far) - unidepth_linearize_depth(texture(dhDepthTex0, gl_FragCoord.xy/view_size).r, dhNearPlane, dhFarPlane);
	
	vec3 reg_clip_space = vec3(gl_FragCoord.xy / view_size, gl_FragCoord.z) * 2.0 - 1.0;
    vec4 reg_view_w = gbufferProjectionInverse * vec4(reg_clip_space, 1.0);
    vec3 reg_view = reg_view_w.xyz / reg_view_w.w;

    // vec3 dh_clip_space = vec3(gl_FragCoord.xy, texture(dhDepthTex0, gl_FragCoord.xy/view_size).r) * 2.0 - 1.0;
    // vec4 dh_view_w = dhProjectionInverse * vec4(dh_clip_space, 1.0);
    // vec3 dh_view = dh_view_w.xyz / dh_view_w.w;

    vec3 dh_clip_space = vec3(gl_FragCoord.xy, texture(colortex8, gl_FragCoord.xy/view_size).b) * 2.0 - 1.0;
    vec4 dh_view_w = gbufferProjectionInverse * vec4(dh_clip_space, 1.0);
    vec3 dh_view = dh_view_w.xyz / dh_view_w.w;

	bool dh_mask = texture(colortex8, gl_FragCoord.xy / view_size).r > 0.5 && reg_view.z - dh_view.z <= 0.0;
	#ifdef DISTANT_HORIZONS
	if (dh_mask || should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
	#else
	if (dh_mask) {
	#endif
	// if (should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
		discard;
	}

	// vec3 viewspace = unidepth_get_viewspace_position(gl_FragCoord.xy/view_size, gl_FragCoord.z, texture(LOD_DEPTHTEX, gl_FragCoord.xy/view_size).r, gbufferProjectionInverse, LOD_INV_PROJ);
	vec4 view_w = gbufferProjectionInverse * vec4(gl_FragCoord.xy/view_size * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);
	vec3 viewspace = view_w.xyz / view_w.w;

	vec4 fog_col = get_fog_color(
		gl_FragCoord.xy/view_size, viewspace,
		eyeAltitude,
		FogMats(
			gbufferModelView, gbufferModelViewInverse,
			gbufferProjection, gbufferProjectionInverse,
			LOD_INV_PROJ
		),
		skyColor, fogColor,
		sunPosition, moonPosition,
        eyeBrightness,
		DEFAULT_FOG_PARAMS
	);
	colortex0.rgb = mix(colortex0.rgb, fog_col.rgb, fog_col.a);

	// if (colortex0.a < alphaTestRef || texture(colortex8, gl_FragCoord.xy / view_size).r > 0.5) {
	// 	discard;
	// }

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);
}