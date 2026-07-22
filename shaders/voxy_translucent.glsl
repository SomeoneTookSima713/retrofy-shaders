#include "/effects/options.glsl"
#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/unified_depth.glsl"
#include "/lib/posterization.glsl"

#ifdef RENDER_LMCOORD
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
// layout(location = 3) out vec4 encoded_tangent;
// layout(location = 4) out vec4 encoded_bitangent;
layout(location = 3) out vec4 dh_stuff_mask;
#else
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
// layout(location = 3) out vec4 encoded_tangent;
// layout(location = 4) out vec4 encoded_bitangent;
layout(location = 2) out vec4 dh_stuff_mask;
#endif

/*
struct VoxyFragmentParameters {
    vec4 sampledColour;
    vec2 tile;
    vec2 uv;
    uint face;
    uint modelId;
    vec2 lightMap;
    vec4 tinting;
    uint customId;//Same as iris's modelId
};
*/

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    vec3 normal = vec3(uint((parameters.face>>1)==2), uint((parameters.face>>1)==0), uint((parameters.face>>1)==1)) * (float(int(parameters.face)&1)*2-1);

    // if ((mat3(gbufferModelView) * normal).z < 0.0) {
    //     discard;
    // }

    float normal_influence = float(int(modelIsShaded((modelData[parameters.modelId]))));

    vec2 view_size = vec2(viewWidth, viewHeight);
    vec2 uv = gl_FragCoord.xy / view_size;

    vec4 new_col = parameters.sampledColour * parameters.tinting;
	new_col.rgb *= get_static_light(parameters.lightMap, worldTime, ambientLight, fogColor, BLOCKLIGHT_COLOR * pow(parameters.lightMap.x, 1.2));
	// new_col.rgb *= mix(1.0, get_normal_based_tint(normal, parameters.lightMap.y, gbufferModelViewInverse, sunPosition, moonPosition, worldTime), normal_influence);

    // vec4 view_w = vxProjInv * vec4(gl_FragCoord.xyz / vec3(viewWidth, viewHeight, 1.0) * 2.0 - 1.0, 1.0);
    // vec3 viewspace = view_w.xyz / view_w.w;
    // float curr_z = abs(viewspace.z);

    // // float old_z = float(atomicMin(ssbo_depth_buf[int(gl_FragCoord.x) + int(gl_FragCoord.y*viewWidth)], uint(curr_z * 16.0))) / 16.0;
    // float old_z;
    // // if (abs(old_z - 2048.0) < 0.01) {
    // if (true) {
    //     vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    //     vec4 old_view_w = vxProjInv * vec4(vec3(uv, texture(vxDepthTexOpaque, uv).r) * 2.0 - 1.0, 1.0);
    //     old_z = abs(old_view_w.z / old_view_w.w);
    // }
    // vec3 old_viewspace = viewspace / viewspace.z * old_z;

    // // new_col.r = old_z - curr_z > 8.0 ? 1.0 : 0.0;
    // // float old_depth = texture(vxDepthTexTrans, uv).r;

    // vec4 old_fog_col = get_fog_color(
    //     uv, old_viewspace, old_z - curr_z,
    //     eyeAltitude,
    //     FogMats(
    //         gbufferModelView, gbufferModelViewInverse,
    //         gbufferProjection, gbufferProjectionInverse,
    //         vxProjInv
    //     ),
    //     skyColor, fogColor,
    //     sunPosition, moonPosition,
    //     eyeBrightness,
    //     DEFAULT_FOG_PARAMS
    //     // FogPlanes(near, far, dhNearPlane, dhFarPlane)
    // );

    // float alpha_value = mix(old_fog_col.a, 1.0, new_col.a);
    // float old_fog_rgb_mult = old_fog_col.a*(1 - new_col.a);

    // colortex0.rgb = (old_fog_col.rgb * old_fog_rgb_mult + new_col.rgb * new_col.a)/alpha_value;
    // colortex0.a = alpha_value;

    // if (old_depth < 1.0) {
    //     // We need to add the fog normally added to opaque terrain already, as it would otherwise have none at all.

    // } else {
    //     // No need for any fancy baked blending equations or fog, just supply the translucent's color

    //     colortex0 = new_col;
    // }
    colortex0 = new_col;

    // colortex0.rgb = (colortex0.rgb * colortex0.a + new_col.rgb * new_col.a) / (1.0 - colortex0.a);
    // colortex0.a += new_col.a - colortex0.a * new_col.a;

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);

    // TODO (if this data ever gets used)
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);

	// dh_stuff_mask = vec4(0.0, 1.0, gl_FragCoord.z * 0.5 + 0.5, 1.0);
    if (texture(depthtex0, uv).r == 1.0) {
		dh_stuff_mask = vec4(0.0, 1.0, gl_FragCoord.z, 1.0);
	}

    // // Makeshift depth buffer using atomics; I'd use an image uniform if voxy *let* me...
	// atomicMin(ssbo_depth_buf[int(gl_FragCoord.x) + int(gl_FragCoord.y*viewWidth)], uint(viewspace.z * 16.0));
}

/*
if (texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x < 1.0) {
    discard;
}

colortex0 = color;
colortex0.rgb *= get_static_light(lmcoord, worldTime, ambientLight, fogColor, BLOCKLIGHT_COLOR);
colortex0.rgb *= get_normal_based_tint(normal, lmcoord.y, gl_ModelViewMatrixInverse, sunPosition, moonPosition, worldTime);

if (colortex0.a < alphaTestRef || !should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
    discard;
}

vec2 view_size = vec2(viewWidth, viewHeight);
vec3 viewspace = unidepth_get_viewspace_position(gl_FragCoord.xy/view_size, texture(depthtex0, gl_FragCoord.xy/view_size).r, gl_FragCoord.z, gbufferProjectionInverse, dhProjectionInverse);
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
    DEFAULT_FOG_PARAMS
    // FogPlanes(near, far, dhNearPlane, dhFarPlane)
);
colortex0.rgb = mix(colortex0.rgb, fog_col.rgb, fog_col.a);
*/