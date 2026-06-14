#version 430 compatibility

#include "/effects/options.glsl"

uniform float viewWidth;
uniform float viewHeight;

uniform bool isEyeInWater;

out vec2 texcoord;

out vec2 main_reduced_view_size;
out vec2 hand_reduced_view_size;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	float res_fac_main;
	float res_fac_hand;
	vec2 view_size = vec2(viewWidth, viewHeight);
	
	if (isEyeInWater) {
		res_fac_main = RESOLUTION_TARGET_MAIN_UNDERWATER / viewHeight;
		res_fac_hand = RESOLUTION_TARGET_HAND_UNDERWATER / viewHeight;
	} else {
		res_fac_main = RESOLUTION_TARGET_MAIN / viewHeight;
		res_fac_hand = RESOLUTION_TARGET_HAND / viewHeight;
	}

	res_fac_main = clamp(pow(2, ceil(log(res_fac_main)/log(2.0))), 0.0, 1.0);
	res_fac_hand = clamp(pow(2, ceil(log(res_fac_hand)/log(2.0))), 0.0, 1.0);

	main_reduced_view_size = vec2(viewWidth, viewHeight) * res_fac_main;
	hand_reduced_view_size = vec2(viewWidth, viewHeight) * res_fac_hand;
}