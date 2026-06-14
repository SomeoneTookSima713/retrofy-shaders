#version 430 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

uniform mat4 gbufferProjection;

in vec2 texcoord;
in vec4 color;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;

/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 colortex0;
layout(location = 1) out vec4 encoded_normal;
// layout(location = 2) out vec4 encoded_tangent;
// layout(location = 3) out vec4 encoded_bitangent;
// layout(location = 4) out vec4 encoded_reflectance; // RGBA32F

void main() {
	colortex0 = texture(gtexture, texcoord) * color;
	if (colortex0.a < alphaTestRef && gl_ProjectionMatrix == gbufferProjection) {
		discard;
	}

	encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
	// encoded_tangent = vec4(tangent * 0.5 + 0.5, 1.0);
	// encoded_bitangent = vec4(bitangent * 0.5 + 0.5, 1.0);
}