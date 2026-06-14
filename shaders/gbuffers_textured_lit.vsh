#version 430 compatibility

#include "/effects/vertex_snapping.glsl"
// #define CLH_SAFE_MODE
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;

void main() {
	// gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
	gl_Position = ftransform_snapped(gl_Vertex, gl_ModelViewMatrix, gl_ProjectionMatrix, 0.5);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;
	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(normal, tangent));

	colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif
}