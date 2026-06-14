#ifndef FX_PIXELATED_LIGHTING
#define FX_PIXELATED_LIGHTING

#include "/lib/pixelation.glsl"
#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/dither.glsl"
#include "/lib/posterization.glsl"

#if LIGHT_POSTERIZATION_COLSPACE == 0 // HSV
	#define RGB_TO_PLCP(value) 
#elif LIGHT_POSTERIZATION_COLSPACE == 1 //

#else

#endif

vec3 hsv_posterize(vec3 color, float color_amount) {
	#if LIGHT_POSTERIZATION_COLSPACE == 1 // OkLAB
		return oklab2rgb(posterize(rgb2oklab(color), color_amount));
	#else // HSV / Fallback
	    return hsv2rgb(posterize(rgb2hsv(color), color_amount));
	#endif
}

vec3 hsv_posterize_dithered(vec3 color, float color_amount, vec2 dither_position) {
	#if LIGHT_POSTERIZATION_COLSPACE == 1 // OkLAB
		vec3 color_oklab = rgb2oklab(color);
		vec3 floored = POSTERIZE_TOWARDS_ZERO(color_oklab, color_amount);
		vec3 ceiled = POSTERIZE_AWAY_FROM_ZERO(color_oklab, color_amount);

		if (floored.x < 0.11 || floored.x > 0.95) {
			return oklab2rgb(floored);
		}

		vec3 dist_lower = abs(color_oklab - floored);
		vec3 dist = dist_lower / abs(ceiled - floored);
		dist = sign(dist - 0.5)*clamp(abs(dist - 0.5) / (1.0 - DITHERING_REDUCTION), 0.0, 0.5) + 0.5;
		vec3 dither = dither8x8(dither_position, dist);

		#if LIGHT_DITHERING_MODE == 0
			return oklab2rgb(vec3(mix(floored.x, ceiled.x, dither.x), floored.yz));
		#elif LIGHT_DITHERING_MODE == 1
			return oklab2rgb(mix(floored, ceiled, dither));
		#else
			// Fallback: No Dithering
			return oklab2rgb(floored);
		#endif
	#else // HSV / Fallback
		vec3 color_hsv = pow(rgb2hsv(color), vec3(1.0, 1.0, 0.5));
		vec3 floored = posterize(color_hsv, color_amount);
		vec3 ceiled = posterize_ceil(color_hsv, color_amount);

		if (floored.z < 0.32 || floored.z > 0.95) {
			return hsv2rgb(pow(floored, vec3(1.0, 1.0, 2.0)));
		}

		vec3 dist_lower = abs(color_hsv - floored);
		vec3 dist = dist_lower / abs(ceiled - floored);
		dist = sign(dist - 0.5)*clamp(abs(dist - 0.5) / (1.0 - DITHERING_REDUCTION), 0.0, 0.5) + 0.5;
		vec3 dither = dither8x8(dither_position, dist);

		#if LIGHT_DITHERING_MODE == 0
			return hsv2rgb(pow(vec3(floored.xy, mix(floored.z, ceiled.z, dither.z)), vec3(1.0, 1.0, 2.0)));
		#elif LIGHT_DITHERING_MODE == 1
			return hsv2rgb(pow(mix(floored, ceiled, dither), vec3(1.0, 1.0, 2.0)));
		#else
			// Fallback: No Dithering
			return hsv2rgb(pow(floored, vec3(1.0, 1.0, 2.0)));
		#endif
	#endif
}

vec2 pixelate_lmcoord(sampler2D gtexture, vec2 texcoord, vec2 lmcoord, inout vec2 texel_offset) {
	#ifdef FX_PIXELATED_LIGHTING_EXTRA_CHECKS
		if (max(length(dFdx(lmcoord)), length(dFdy(lmcoord))) > 1.414/32.0) {
			return lmcoord;
		}
	#endif
	texel_offset = compute_texel_offset(gtexture, texcoord, LIGHT_PIXELATION_MULT);
	return texel_snap(lmcoord, texel_offset);
}

vec3 get_posterized_lightcol(sampler2D lightmap, vec2 pixelated_lmcoord) {
	return hsv_posterize(texture(lightmap, pixelated_lmcoord).rgb, LIGHT_COLOR_AMOUNT);
}

vec3 get_posterized_lightcol(sampler2D lightmap, sampler2D gtexture, vec2 texcoord, vec2 lmcoord) {
	vec2 texel_offset;
	return hsv_posterize(texture(lightmap, pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset)).rgb, LIGHT_COLOR_AMOUNT);
}

vec3 get_static_light(vec2 lmcoord, int worldTime, float ambient_light, vec3 fog_color, vec3 blocklight_color) {
	#ifdef THE_END
		lmcoord.y = 0.0;
	#else
		lmcoord.y = clamp(lmcoord.y, 1.0/32.0, 31.0/32.0);
	#endif

	float lm_y = clamp((abs(mod(worldTime / 24000.0 - 0.25, 1.0) - 0.5)*2-0.4375)*8, 0.0, 1.0);

	#if defined NETHER
		vec3 skylight = hsv2rgb(vec3(rgb2hsv(fog_color).xy, 1.0)*SKYLIGHT_COLOR_HSV_MULT) * lmcoord.y;
	#elif defined AETHER
		vec3 skylight = SKYLIGHT_COLOR * lmcoord.y;
	#else
		vec3 skylight = mix(SKYLIGHT_COLOR_NIGHT, SKYLIGHT_COLOR, lm_y) * lmcoord.y;
	#endif

	// vec3 default_hsv = rgb2hsv(BLOCKLIGHT_COLOR);
	// // vec3 blocklight = rgb2hsv(mix(BLOCKLIGHT_COLOR, blocklight_color, pow(rgb2hsv(blocklight_color).z, 0.5)));
	// vec3 blocklight = rgb2hsv(blocklight_color);
	// blocklight.z = max(blocklight.z, default_hsv.z);
	// blocklight = hsv2rgb(blocklight);
	// blocklight *= pow(lmcoord.x, 1.2);
	vec3 blocklight = blocklight_color;
	lmcoord.x = rgb2hsv(blocklight_color).z;

	// return vec3(lmcoord, clamp(MINIMUM_LIGHT.a - lmcoord.x - lmcoord.y, 0.0, 1.0));
	return skylight + max(blocklight * (1-(skylight.r+skylight.g+skylight.b)/3), vec3(0.0)) + MINIMUM_LIGHT.rgb * clamp(AMBIENT_LIGHT_ADD - lmcoord.x - lmcoord.y, 0.0, 1.0);
}

vec3 get_posterized_lightcol_static_lightmap(sampler2D gtexture, vec2 texcoord, vec2 lmcoord, int worldTime, float ambient_light, vec3 fog_color, vec3 blocklight_color) {
	vec2 texel_offset;
	vec2 pixelated_lmcoord = pixelate_lmcoord(gtexture, texcoord, lmcoord, texel_offset);
	
	return hsv_posterize(get_static_light(pixelated_lmcoord, worldTime, ambient_light, fog_color, blocklight_color), LIGHT_COLOR_AMOUNT);
}

#endif