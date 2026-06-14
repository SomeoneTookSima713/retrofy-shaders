#version 430 compatibility

#define CLH_SAFE_MODE
#define IMPL_DITHER
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

// in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_Entity;
in vec2 mc_midTexCoord;

out vec2 lmcoord;
out vec2 texcoord;
out vec3 color;
out float ao;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;
out float normal_influence;

#ifdef DISTANT_HORIZONS
	out float far_plane_distance;
#endif

#ifndef IS_IRIS
out vec2 surface_tangent_world_pos;
// out vec3 blocklight_color;
#endif

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color.rgb;
	ao = gl_Color.a;
	normal = normalize(gl_Normal);
	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(normal, tangent));
	normal_influence = 1.0 - at_midBlock.w / 15.0;
	#ifdef DISTANT_HORIZONS
		far_plane_distance = far - length(gl_Vertex.xyz);
	#endif

    bool is_sable = gl_ModelViewMatrix != gbufferModelView;

	if (!is_sable) {
        colored_lighting_compute_vertex_outputs_terrain(at_midBlock, normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
    } else {
        colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
        surface_tangent_world_pos = vec2(0.0);
    }
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif

    #ifndef FULL_SHADOW_PASS
        colored_lighting_voxelize_terrain(
            block_centered_relative_pos,
            mc_Entity,
            at_midBlock,
            mc_midTexCoord,
            texcoord,
            normal,
            is_sable,
            true,
            gtexture,
            atlasSize,
            frameCounter
        );
    #endif
}