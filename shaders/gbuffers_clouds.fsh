#version 430 compatibility

#include "/lib/lod_utils.glsl"

uniform sampler2D gtexture;

#ifdef LODS_ENABLED
uniform sampler2D LOD_DEPTHTEX_FULL;
#endif

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 color;
in vec3 normal;
// in vec3 tangent;
// in vec3 bitangent;
#ifdef LODS_ENABLED
in float lod_depth;
#endif

#ifdef RENDER_LMCOORD
/* RENDERTARGETS: 0,1,7 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
#else
/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 colortex0;
// layout(location = 1) out vec4 lightmap_data;
layout(location = 1) out vec4 encoded_normal;
#endif

void main() {
	colortex0 = texture(gtexture, texcoord) * color;
    colortex0.rgb = vec3(1.0, 0.0, 0.0);
	// colortex0 = vec4(1.0, 0.0, 0.0, 1.0);
	// if (colortex0.a < alphaTestRef) {
	// 	discard;
	// }

	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);
}