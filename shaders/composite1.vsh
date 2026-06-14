#version 430 compatibility

#include "/effects/options.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform bool isEyeInWater;

out vec2 texcoord;

flat out int screen_res_mult;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	float res_fac_main;
	
	if (isEyeInWater) {
		res_fac_main = RESOLUTION_TARGET_MAIN_UNDERWATER / viewHeight;
	} else {
		res_fac_main = RESOLUTION_TARGET_MAIN / viewHeight;
	}

	res_fac_main = clamp(pow(2, ceil(log(res_fac_main)/log(2.0))), 0.0, 1.0);

	screen_res_mult = int(1/res_fac_main);
}