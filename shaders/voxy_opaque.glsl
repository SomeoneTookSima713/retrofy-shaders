#include "/effects/pixelated_lighting.glsl"
#include "/lib/normal_based_lighting.glsl"

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

    colortex0 = parameters.sampledColour * parameters.tinting;
	colortex0.rgb *= get_static_light(parameters.lightMap, worldTime, ambientLight, fogColor, BLOCKLIGHT_COLOR * pow(parameters.lightMap.x, 1.2));
	colortex0.rgb *= mix(1.0, get_normal_based_tint(normal, parameters.lightMap.y, gbufferModelViewInverse, sunPosition, moonPosition, worldTime), normal_influence);

	#ifdef RENDER_LMCOORD
		lightmap_data = vec4(lmcoord, 0.0, 1.0);
	#endif
	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);

	vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

	vec4 view_w = vxProjInv * vec4(uv * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);

	// // Makeshift depth buffer using atomics; I'd use an image uniform if voxy *let* me...
	// atomicMin(ssbo_depth_buf[int(gl_FragCoord.x) + int(gl_FragCoord.y*viewWidth)], uint(view_w.z / view_w.w * 16.0));

    // TODO (if this data ever gets used)
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);

	if (texture(depthtex0, uv).r == 1.0) {
		dh_stuff_mask = vec4(0.0, 1.0, gl_FragCoord.z, 1.0);
	}
}