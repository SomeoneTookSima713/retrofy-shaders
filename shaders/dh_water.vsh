#version 430 compatibility

uniform bool isEyeInWater;
uniform float far;

// uniform mat4 gbufferModelView;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferProjection;
// uniform mat4 gbufferProjectionInverse;

uniform vec4 lod_regular_viewspace_z_vec;
uniform vec4 lod_regular_viewspace_w_vec;

in vec4 at_tangent;

out vec2 lmcoord;
out vec4 color;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;
out float far_plane_distance;
// out vec4 regular_viewspace_coord;
out float regular_clip_depth;

// Necessary for VSCode
#ifndef dhMaterialId
	#define dhMaterialId 0
	#define DH_BLOCK_WATER 0
#endif

void main() {
	vec4 view = gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * view;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;
	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(normal, tangent));
	// far_plane_distance = far - length(mat3(gbufferModelViewInverse) * ((gbufferProjectionInverse * gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex).xyz));
	far_plane_distance = far - length(gl_Vertex.xyz);

	// regular_viewspace_coord = gbufferProjection * gl_ModelViewMatrix * gl_Vertex;
	
	// dot(...) / dot(...) * 0.5 + 0.5
	regular_clip_depth = fma(dot(lod_regular_viewspace_z_vec, view) / dot(lod_regular_viewspace_w_vec, view), 0.5, 0.5);
}