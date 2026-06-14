#version 430 compatibility

#define CLH_SAFE_MODE
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"
#define VOXELIZE_ENTITIES
#include "/effects/colored_lighting/voxelization.glsl"

uniform sampler2D gtexture;

uniform ivec2 atlasSize;

uniform float far;

uniform int currentRenderedItemId;

uniform int entityId;

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

in vec2 mc_midTexCoord;
in vec3 at_tangent;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec4 normal;
// out vec3 tangent;
// out vec3 bitangent;
out float far_plane_distance;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = vec4(gl_Normal, entityId == 300 ? 0.0 : 1.0);
	far_plane_distance = far - length(gl_Vertex.xyz);

	colored_lighting_compute_vertex_outputs_general(normal.xyz, cameraPositionFract, previousCameraPositionFract, frameCounter);
    blocklight = entityId == 300 ? vec4(BLOCKLIGHT_COLOR, lmcoord.x) : blocklight;
	#ifndef DO_COLORED_LIGHTING
		blocklight = vec4(BLOCKLIGHT, lmcoord.x);
	#endif

    vec3 world_vert_pos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz;
    colored_lighting_voxelize_entities(
        world_vert_pos,
        texcoord,
        mc_midTexCoord,
        currentRenderedItemId,
        gtexture,
        atlasSize,
        frameCounter
    );
}