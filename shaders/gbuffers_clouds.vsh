#version 430 compatibility

#include "/lib/lod_utils.glsl"

#ifdef LODS_ENABLED
uniform mat4 LOD_MODEL_VIEW;
uniform mat4 LOD_PROJ;
#endif

// in vec4 at_tangent;

out vec2 texcoord;
out vec4 color;
out vec3 normal;
// out vec3 tangent;
// out vec3 bitangent;
#ifdef LODS_ENABLED
out float lod_depth;
#endif

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	normal = gl_Normal;

    #ifdef LODS_ENABLED
        vec4 lod_space_w = LOD_PROJ * LOD_MODEL_VIEW * gl_Vertex;
        lod_depth = lod_space_w.z / lod_space_w.w;
    #endif

	// tangent = normalize(at_tangent.xyz / at_tangent.w);
	// bitangent = normalize(cross(normal, tangent));
}