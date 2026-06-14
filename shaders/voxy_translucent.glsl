#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/normal_based_lighting.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/unified_depth.glsl"

// This needs to be updated when the same function in /effects/pixelated_lighting.glsl gets updated!
vec3 get_static_light(vec2 lmcoord, int worldTime, float ambient_light, vec3 fog_color, vec3 blocklight_color) {
	#ifdef THE_END
		lmcoord.y = AMBIENT_LIGHT_ADD;
	#else
		lmcoord.y = clamp(lmcoord.y + AMBIENT_LIGHT_ADD, 1.0/32.0, 31.0/32.0);
	#endif

	float lm_x = clamp((abs(mod(worldTime / 24000.0 - 0.25, 1.0) - 0.5)*2-0.4375)*8, 0.0, 1.0);

	#if defined NETHER
		vec3 skylight = hsv2rgb(vec3(rgb2hsv(fog_color).xy, 1.0)*SKYLIGHT_COLOR_HSV_MULT) * lmcoord.y;
	#elif defined AETHER
		vec3 skylight = SKYLIGHT_COLOR * lmcoord.y;
	#else
		vec3 skylight = mix(SKYLIGHT_COLOR_NIGHT, SKYLIGHT_COLOR, lm_x) * lmcoord.y;
	#endif

	// vec3 blocklight = blocklight_color * pow(lmcoord.x, 1.2);
    vec3 blocklight = blocklight_color;
	lmcoord.x = rgb2hsv(blocklight_color).z;

	return skylight + max(blocklight * (1-(skylight.r+skylight.g+skylight.b)/3), vec3(0.0)) + MINIMUM_LIGHT.rgb * clamp(MINIMUM_LIGHT.a - lmcoord.x - lmcoord.y, 0.0, 1.0);
}

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

    float normal_influence = float(int(modelIsShaded((modelData[parameters.modelId]))));

    vec2 view_size = vec2(viewWidth, viewHeight);
    vec2 uv = gl_FragCoord.xy / view_size;

    vec4 new_col = parameters.sampledColour * parameters.tinting;
	new_col.rgb *= get_static_light(parameters.lightMap, worldTime, ambientLight, fogColor, BLOCKLIGHT_COLOR * parameters.lightMap.x);
	new_col.rgb *= mix(1.0, get_normal_based_tint(normal, parameters.lightMap.y, gbufferModelViewInverse, sunPosition, moonPosition, worldTime), normal_influence);

    // float old_z = float(ssbo_depth_buf[int(gl_FragCoord.x) + int(gl_FragCoord.y*viewWidth)]) / 16.0;
    float old_depth = texture(vxDepthTexTrans, uv).r;

    vec4 old_view_w = vxProjInv * vec4(uv * 2.0 - 1.0, old_depth * 2.0 - 1.0, 1.0);
    vec4 view_w = vxProjInv * vec4(uv * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);

    vec3 old_viewspace = old_view_w.xyz / old_view_w.w;
    vec3 viewspace = view_w.xyz / view_w.w;
    // vec3 old_viewspace = vec3(viewspace.xy, old_z);

    if (old_depth < 1.0) {
        // We need to add the fog normally added to opaque terrain already, as it would otherwise have none at all.

        vec4 old_fog_col = get_fog_color(
            uv, old_viewspace, distance(old_viewspace, viewspace),
            eyeAltitude,
            FogMats(
                gbufferModelView, gbufferModelViewInverse,
                gbufferProjection, gbufferProjectionInverse,
                vxProjInv
            ),
            skyColor, fogColor,
            sunPosition, moonPosition,
            DEFAULT_FOG_PARAMS
            // FogPlanes(near, far, dhNearPlane, dhFarPlane)
        );

        float alpha_value = mix(old_fog_col.a, 1.0, new_col.a);
        float old_fog_rgb_mult = old_fog_col.a*(1 - new_col.a);

        colortex0.rgb = (old_fog_col.rgb * old_fog_rgb_mult + new_col.rgb * new_col.a)/alpha_value;
        colortex0.a = alpha_value;
    } else {
        // No need for any fancy baked blending equations or fog, just supply the translucent's color

        colortex0 = new_col;
    }

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
		dh_stuff_mask = vec4(0.0, 1.0, gl_FragCoord.z * 0.5 + 0.5, 1.0);
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