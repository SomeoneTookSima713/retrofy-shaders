#version 430 compatibility

#define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"
#include "/effects/colored_lighting/voxelization.glsl"

uniform sampler2D gtexture;

uniform bool isEyeInWater;
uniform float far;

uniform mat4 gbufferModelView;

uniform ivec2 atlasSize;

uniform int renderStage;
uniform int frameCounter;

uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

in vec2 mc_Entity;
in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec3 normal;
flat out int is_sable;
// out vec3 tangent;
// out vec3 bitangent;

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
	color = gl_Color;
	normal = gl_Normal;
	vec3 tangent = normalize(at_tangent.xyz / at_tangent.w);
	vec3 bitangent = normalize(cross(normal, tangent));

    bool is_sable_bool = gl_ModelViewMatrix != gbufferModelView;
    is_sable = int(is_sable_bool);

	#ifdef DISTANT_HORIZONS
		far_plane_distance = far - length(gl_Vertex.xyz);
	#endif

    #ifdef DEBUG_COLORED_LIGHTING
        frag_at_midBlock = at_midBlock.xyz / 64.0;
    #endif

	colored_lighting_compute_vertex_outputs_terrain(at_midBlock, normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight = vec4(BLOCKLIGHT_COLOR, lmcoord.x);
	#endif

	// colored_lighting_voxelize_terrain(gl_Vertex.xyz, gtexture, texcoord, atlasSize, mc_Entity, at_midBlock, frameCounter);
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
}