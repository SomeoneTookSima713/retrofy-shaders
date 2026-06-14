#version 430 compatibility

#include "/effects/fog_and_sky.glsl"

uniform int renderStage;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float sunAngle;
uniform float wetness;
uniform float rainStrength;
uniform float thunderStrength;

uniform ivec3 cameraPositionInt;
uniform vec3 cameraPosition;

uniform bool isEyeInWater;

uniform ivec2 eyeBrightness;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor;
		// discard;
	} else {
		vec4 pos_w = gbufferProjectionInverse * (vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0, 1.0) * 2.0 - vec4(1.0));
		FogMats mats = DEFAULT_FOG_MATS;
		color = vec4(sky_calc_color(normalize(pos_w.xyz / pos_w.w)*100.0, mats, skyColor, fogColor, sunPosition, moonPosition, eyeBrightness, eval_values(DEFAULT_FOG_PARAMS, mats)), 1.0);
	}
}
