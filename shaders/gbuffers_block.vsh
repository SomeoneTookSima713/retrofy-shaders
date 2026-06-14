#version 430 compatibility

#include "/effects/vertex_snapping.glsl"
// #define CLH_SAFE_MODE
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform int renderStage;

uniform float far;

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;
out float far_plane_distance;

void main() {
	float precision_mult = 0.5;
	if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES) {
		precision_mult = 16.0;
	}

	gl_Position = ftransform_snapped(gl_Vertex, gl_ModelViewMatrix, gl_ProjectionMatrix, precision_mult);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;
	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(normal, tangent));
	far_plane_distance = far - length(gl_Vertex.xyz);

	colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif
}