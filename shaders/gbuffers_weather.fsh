#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/pixelated_lighting.glsl"
#include "/lib/colors.glsl"
#include "/effects/colored_lighting/fragment.glsl"
#include "/lib/weather_encoding.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D lightmap;

uniform int worldTime;

uniform float ambientLight;
uniform vec3 fogColor;

uniform mat4 gbufferModelView;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 simple_normal;

/* RENDERTARGETS: 3 */
layout(location = 0) out uvec4 out_weather_data;
// layout(location = 1) out vec4 out_debug;

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;
	vec4 normal = texture(normals, texcoord);

	if (color.a < alphaTestRef) {
		discard;
	}
	color.a *= 0.8;

    // out_debug = vec4(0.0);

	#ifdef RAIN_REFRACTION
	if (length(abs(normal * 255.0 - vec4(127, 127, 255, 255))) < 0.01) {
	#else
	if (true) {
	#endif

		// color.rgb *= get_static_light(lmcoord, worldTime, ambientLight, fogColor, blocklight_color);
		vec2 texel_offset;
		vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);

		#ifdef DO_COLORED_LIGHTING
            pixelated_lmcoord.x = texel_snap(blocklight.a, texel_offset);
			vec3 final_blocklight = colored_lighting_get_blocklight(pixelated_lmcoord, texel_offset);
		#else
			vec3 final_blocklight = BLOCKLIGHT_COLOR * pow(pixelated_lmcoord.x, 1.2);
		#endif
		
		// #ifdef DITHER_LIGHTING
		// 	color.rgb *= hsv_posterize_dithered(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT, surface_tangent_world_pos);
		// #else
        color.rgb *= hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambientLight, fogColor, final_blocklight), LIGHT_COLOR_AMOUNT);
		// #endif

        // Bit format:
        // 1AAAAAAA BBBBBBBB GGGGGGGG RRRRRRRR
        out_weather_data.x = weatherenc_encode_regular_weather(color);
	} else {
		// color.rg = (0.5 * simple_normal.xy + 0.5 * normal.xy) * 0.5 + 0.5;
		// color.b = gl_FragCoord.z;
		// color.a = 1.6;

        vec2 normal_data = 0.33 * simple_normal.xy + 0.67 * normal.xy;

        // Bit format:
        // 0DDDDDDD DDDDDDDD DDDDYYYY YYXXXXXX
        // D - Depth
        // Y - Normal Y
        // X - Normal X
        out_weather_data.x = weatherenc_encode_refracting_rain(normal_data, gl_FragCoord.z);
        // out_debug.rg = normal_data;
	}
}