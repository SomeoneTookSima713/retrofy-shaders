#version 430 compatibility

// #define CLH_SAFE_MODE
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform float far;
uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 simple_normal;

void main() {
	vec3 rain_slant = vec3(0.2, 0.0, 0.1);

	vec4 viewspace = gl_ModelViewMatrix * (gl_Vertex+vec4(rain_slant, 0.0)*(gl_Vertex.y + gl_ModelViewMatrix[3].y)) * 1.1;
	gl_Position = gl_ProjectionMatrix * viewspace;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	simple_normal = -normalize(viewspace.xyz - gl_ModelViewMatrix[1].xyz * dot(viewspace.xyz, gl_ModelViewMatrix[1].xyz));

	colored_lighting_compute_vertex_outputs_general(normalize(gl_Normal), cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif
}