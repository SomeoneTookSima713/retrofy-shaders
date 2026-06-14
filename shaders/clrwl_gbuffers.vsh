#version 430 compatibility

#include "/effects/vertex_snapping.glsl"
#define CLH_SAFE_MODE
#define CLH_MANUAL_POS_ATTRIBS
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform float far;

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;
uniform ivec3 cameraPositionInt;

// uniform mat4 gbufferModelViewInverse;

in vec4 at_midBlock;

out vec2 texcoord;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;
out float far_plane_distance;

void main() {
	gl_Position = ftransform_snapped(gl_Vertex, gl_ModelViewMatrix, gl_ProjectionMatrix, 1.0);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	normal = gl_Normal;
	far_plane_distance = far - length(gl_Vertex.xyz);

	vec3 foot_pos = (gbufferModelViewInverse * vec4((gl_ModelViewMatrix * gl_Vertex).xyz, 1.0)).xyz;

	block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 + cameraPositionFract;
	relative_pos = foot_pos + cameraPositionFract + VOXEL_AREA_RADIUS;

	colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif
}