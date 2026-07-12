#version 430 compatibility

#define CLH_SAFE_MODE
#define IMPL_DITHER
#include "/effects/options.glsl"
#include "/effects/colored_lighting/vertex.glsl"
#include "/effects/colored_lighting/voxelization.glsl"

uniform sampler2D gtexture;

uniform float far;

uniform mat4 gbufferModelView;

uniform ivec2 atlasSize;

uniform int renderStage;
uniform int frameCounter;

uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_Entity;
in vec2 mc_midTexCoord;

out vec2 lmcoord;
out vec2 texcoord;
out vec3 color;
out float ao;
out vec3 normal;
out vec3 tangent;
// out vec3 bitangent;
out float normal_influence;
flat out int is_sable;

#ifdef DISTANT_HORIZONS
	out float far_plane_distance;
#endif

#ifdef DEBUG_COLORED_LIGHTING
    out vec3 frag_at_midBlock;
    flat out int dbg_did_voxelize;
    flat out int dbg_overwrote_value;
    flat out int dbg_passable;
    flat out int dbg_passability_mask;
    flat out int dbg_passability_mask_pos;
#endif

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color.rgb;
	ao = gl_Color.a;
	normal = normalize(gl_Normal);
	tangent = normalize(at_tangent.xyz / at_tangent.w);
	vec3 bitangent = normalize(cross(normal, tangent));
	normal_influence = 1.0 - at_midBlock.w / 15.0;
	#ifdef DISTANT_HORIZONS
		far_plane_distance = far - length(gl_Vertex.xyz);
	#endif

    #ifdef DEBUG_COLORED_LIGHTING
        frag_at_midBlock = at_midBlock.xyz / 64.0;
    #endif

    bool is_sable_bool = gl_ModelViewMatrix != gbufferModelView;
    is_sable = int(is_sable_bool);

	if (!is_sable_bool) {
        colored_lighting_compute_vertex_outputs_terrain(at_midBlock, normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
    } else {
        colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
        #ifdef DITHER_LIGHTING
        surface_tangent_world_pos = vec2(0.0);
        #endif
    }
	#ifndef DO_COLORED_LIGHTING
		blocklight = vec4(BLOCKLIGHT_COLOR, lmcoord.x);
	#endif

    #ifndef FULL_SHADOW_PASS
        colored_lighting_voxelize_terrain(
            block_centered_relative_pos,
            mc_Entity,
            at_midBlock,
            mc_midTexCoord,
            texcoord,
            tangent,
            bitangent,
            normal,
            is_sable_bool,
            true,
            gtexture,
            atlasSize,
            frameCounter
            #ifdef DEBUG_COLORED_LIGHTING
            , dbg_did_voxelize,
            dbg_passable,
            dbg_passability_mask,
            dbg_passability_mask_pos,
            dbg_overwrote_value
            #endif
        );
    #endif

    // color = mat2x3(tangent, bitangent) * (mc_midTexCoord - texcoord);
    // ivec3 at_midBlock_signage = ivec3(notEqual(at_midBlock.xyz, vec3(0.0))) * ivec3(-sign(at_midBlock.xyz) * 0.5 + 1.5);
    // color = vec3(sign(-at_midBlock.xyz));
}