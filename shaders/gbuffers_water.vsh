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
// out vec3 tangent;
// out vec3 bitangent;

#ifdef DISTANT_HORIZONS
	out float far_plane_distance;
#endif

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;
	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(vertex.normal, vertex.tangent));

	#ifdef DISTANT_HORIZONS
		far_plane_distance = far - length(gl_Vertex.xyz);
	#endif

	colored_lighting_compute_vertex_outputs_terrain(at_midBlock, normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif

	// colored_lighting_voxelize_terrain(gl_Vertex.xyz, gtexture, texcoord, atlasSize, mc_Entity, at_midBlock, frameCounter);
    #ifndef FULL_SHADOW_PASS
        colored_lighting_voxelize_terrain(
            block_centered_relative_pos,
            mc_Entity,
            at_midBlock,
            mc_midTexCoord,
            texcoord,
            normal,
            gl_ModelViewMatrix != gbufferModelView,
            true,
            gtexture,
            atlasSize,
            frameCounter
        );
    #endif
}