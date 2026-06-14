#version 430 compatibility

#include "/lib/colors.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

uniform int renderStage;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;

	if (color.a < alphaTestRef) {
		discard;
	}
}