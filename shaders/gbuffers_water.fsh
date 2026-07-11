#version 430 compatibility

#include "/effects/pixelated_lighting.glsl"
#include "/effects/options.glsl"
#include "/effects/ssr.glsl"
#include "/effects/fog_and_sky.glsl"
// #include "/lib/blur.glsl"
#include "/lib/dh_interp.glsl"
// #include "/lib/cam_utils.glsl"
#include "/lib/unified_depth.glsl"
#include "/lib/voxelization_encoding.glsl"
#include "/effects/colored_lighting/fragment.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex8;
uniform sampler2D depthtex0;

#ifdef DEBUG_COLORED_LIGHTING
    layout(r32ui) uniform uimage3D voxel_img;
    uniform usampler3D voxel_img_sampler;
    uniform sampler3D color_img_sampler;
    uniform sampler3D color_img_flip_sampler;

    #define CLH_READ_COLOR(read_pos) (((frameCounter & 1) == 0) ? imageLoad(color_img, read_pos) : imageLoad(color_img_flip, read_pos))
    #define CLH_SAMPLE_COLOR(read_pos) (((frameCounter & 1) == 0) ? texture3D(color_img_sampler, read_pos) : texture3D(color_img_flip_sampler, read_pos))
#endif

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
uniform vec3 cameraPositionFract;

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

uniform int frameCounter;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;
#ifdef DISTANT_HORIZONS
	in float far_plane_distance;
#endif

#ifdef DEBUG_COLORED_LIGHTING
    in vec3 frag_at_midBlock;
    flat in int dbg_did_voxelize;
    flat in int dbg_overwrote_value;
    flat in int dbg_passable;
    flat in int dbg_passability_mask;
    flat in int dbg_passability_mask_pos;
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

	bool dh_mask = false; //texture(colortex8, gl_FragCoord.xy / view_size).r > 0.5 && clamp(reg_view.z - dh_view.z, -8.0, 2.0) == reg_view.z - dh_view.z;
	#ifdef DISTANT_HORIZONS
	if (dh_mask || should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
	#else
	if (dh_mask) {
	#endif
	// if (should_discard_with_blur(far_plane_distance, gl_FragCoord.xy)) {
		discard;
        // colortex0.rgb = vec3((dh_view.z - reg_view.z) * 0.01);
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

    #ifdef DEBUG_COLORED_LIGHTING
        vec4 world_pos_w = gbufferModelViewInverse * gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, gl_FragCoord.z * 2.0 - 1.0, 1.0);
        vec3 world_pos = world_pos_w.xyz / world_pos_w.w;
        vec3 voxel_pos_float = block_centered_relative_pos + float(VOXEL_AREA_RADIUS);
        ivec3 voxel_pos_int = ivec3(block_centered_relative_pos + VOXEL_AREA_RADIUS);
		#ifdef DEBUG_CL_FLOODFILL_COLOR
            colortex0.rgb = (CLH_SAMPLE_COLOR((world_pos + cameraPositionFract + float(VOXEL_AREA_RADIUS))/float(VOXEL_AREA_SIZE))).rgb;
        #endif
        #if defined DEBUG_CL_VOXEL_COLOR || defined DEBUG_CL_VOXEL_INFO
            uint voxel_color_payload = imageLoad(voxel_img, voxel_pos_int).r;
            uint voxel_info_payload = imageLoad(voxel_img, voxel_pos_int + ivec3(0, VOXEL_AREA_SIZE, 0)).r;
            vec4 voxel_color = decode_color_and_light(voxel_color_payload);
            VoxelInfo voxel_info = decode_voxel_info(voxel_info_payload);
        #endif

        #ifdef DEBUG_CL_VOXEL_COLOR
            if (!voxel_info_is_empty(voxel_info) && voxel_info.is_light) {
                colortex0.rgb = voxel_color.rgb;
            }
        #endif
        #ifdef DEBUG_CL_VOXEL_INFO
            #ifdef DEBUG_CL_VOXEL_INFO
                #define DBG_CLVI_DISPCOND (!voxel_info.is_light || frag_at_midBlock.x > 0.0)
            #else
                #define DBG_CLVI_DISPCOND true
            #endif

            if (!voxel_info_is_empty(voxel_info) && DBG_CLVI_DISPCOND) {
                #if DEBUG_CL_VOXEL_INFO_MODE == 0
                    vec3[] colors = vec3[](
                        voxel_info.is_passable ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.tints_light ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.is_gbuffers ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 3.0), 0, 2)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 1
                    vec3[] colors = vec3[](
                        vec3(1.0, 0.5, 0.0) * float(voxel_info.passability_mask & 1),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 2) >> 1),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 4) >> 2),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 8) >> 3),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 16) >> 4),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 32) >> 5)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 6.0), 0, 5)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 2
                    vec3[] colors = vec3[](
                        voxel_info.is_passable ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.tints_light ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        voxel_info.is_gbuffers ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0),
                        vec3(1.0, 0.5, 0.0) * float(voxel_info.passability_mask & 1),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 2) >> 1),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 4) >> 2),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 8) >> 3),
                        vec3(1.0, 0.5, 0.0) * float((voxel_info.passability_mask & 16) >> 4),
                        vec3(0.5, 1.0, 0.0) * float((voxel_info.passability_mask & 32) >> 5),
                        vec3(1.0, 0.0, 1.0) * float(voxel_info.timestamp) / 16.0
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 10.0), 0, 9)];
                #elif DEBUG_CL_VOXEL_INFO_MODE == 3
                    vec3[] colors = vec3[](
                        vec3(0.5),
                        bool(dbg_did_voxelize) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passable) ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_overwrote_value) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 1) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 2) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 4) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 8) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 16) ? vec3(0.5, 1.0, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask & 32) ? vec3(1.0, 0.5, 0.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 1) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 2) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 4) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 8) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 16) ? vec3(0.0, 0.5, 1.0) : vec3(0.0, 0.0, 0.0),
                        bool(dbg_did_voxelize) && bool(dbg_passability_mask_pos & 32) ? vec3(0.0, 1.0, 0.5) : vec3(0.0, 0.0, 0.0)
                    );
                    colortex0.rgb = colors[clamp(int((frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5) * 16.0), 0, 15)];
                    colortex0.a = 0.5;
                    // colortex0.rgb = vec3(frag_at_midBlock[DEBUG_CL_DISPDIR] + 0.5);
                #endif
            }
        #endif
	#endif

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