#version 430 compatibility

#define CLH_SAFE_MODE
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform int currentRenderedItemId;
uniform int heldItemId;
uniform int heldItemId2;

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec3 normal;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;

	colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif
}