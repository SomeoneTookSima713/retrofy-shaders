#version 430 compatibility

uniform mat4 gbufferProjection;

in vec4 at_tangent;

out vec2 texcoord;
out vec4 color;
out vec3 normal;
out vec3 tangent;
out vec3 bitangent;

void main() {
	if (gl_ProjectionMatrix != gbufferProjection) {
		
	}
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	normal = gl_Normal;
	tangent = normalize(at_tangent.xyz / at_tangent.w);
	bitangent = normalize(cross(normal, tangent));
}