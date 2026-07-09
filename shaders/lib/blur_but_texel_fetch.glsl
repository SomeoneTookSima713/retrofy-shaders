#ifndef LIB_BLUR
#define LIB_BLUR

#define UV_CLAMP(val, dims) clamp(val, ivec2(0), dims)

const int fancy_blur_samples = 7;
const int fancier_blur_samples = 9;
const int fancy_blur_offset = fancier_blur_samples / 2 - 1;
const int fancier_blur_offset = fancier_blur_samples / 2 - 1;

#define FBS fancy_blur_samples
#define FBO fancy_blur_offset
#define FB_RADIUS_FORMULA(VAL,COUNT) radius*falloff_max_dist/(VAL.b/float(COUNT)*(far-near))
vec4 fancy_ceiling_box_blur_x(sampler2D mask, ivec2 coords, ivec2 view_size, float radius, float falloff_max_dist, float near, float far) {
	vec4 currval = texelFetch(mask, coords, 0);
	if (currval.r >= 0.5) {
		return currval;
	}

	vec4 value = vec4(0.0);
	vec4 handheld_value = vec4(0.0);
	int count = 0;
	int handheld_count = 0;
	int nearest_pixel_dist = 1000;
	for (int i=0; i<FBS; i++) {
		vec4 maskval = texelFetch(mask, UV_CLAMP(coords + ivec2(int((i - FBO)*radius/FBO), 0), view_size), 0);
		if (maskval.r < 0.5) { continue; }
		if (maskval.g < 0.5) {
			value += maskval;
			count += 1;
		} else {
			handheld_value += maskval;
			handheld_count += 1;
		}
		if (nearest_pixel_dist > abs(i - FBO)) {
			nearest_pixel_dist = abs(i - FBO);
		}
	}

	if (count <= 1 && handheld_count <= 1) {
		return vec4(0.0);
	} else if (handheld_count > 1) {
		// if (mix(radius, 0, handheld_value.b/float(handheld_count)/falloff_max_dist_rel) < nearest_pixel_dist*radius/float(FBO)) {
		// 	return vec4(0.0);
		// }
		if (FB_RADIUS_FORMULA(handheld_value, handheld_count) < nearest_pixel_dist*radius/float(FBO)) {
			return vec4(0.0);
		}

		return handheld_value / float(handheld_count);
	} else {
		// if (mix(radius, 0, value.b/float(count)/falloff_max_dist_rel) < nearest_pixel_dist*radius/float(FBO)) {
		// 	return vec4(0.0);
		// }
		if (FB_RADIUS_FORMULA(value, count) < nearest_pixel_dist*radius/float(FBO)) {
			return vec4(0.0);
		}

		return value/float(count);
	}
}

vec4 fancy_ceiling_box_blur_y(sampler2D mask, ivec2 coords, ivec2 view_size, float radius, float falloff_max_dist, float near, float far) {
	vec4 currval = texelFetch(mask, coords, 0);
	if (currval.r >= 0.5) {
		return currval;
	}

	vec4 value = vec4(0.0);
	vec4 handheld_value = vec4(0.0);
	int count = 0;
	int handheld_count = 0;
	int nearest_pixel_dist = 1000;
	for (int i=0; i<FBS; i++) {
		vec4 maskval = texelFetch(mask, UV_CLAMP(coords + ivec2(0, int((i - FBO)*radius/FBO)), view_size), 0);
		if (maskval.r < 0.5) { continue; }
		if (maskval.g < 0.5) {
			value += maskval;
			count += 1;
		} else {
			handheld_value += maskval;
			handheld_count += 1;
		}
		if (nearest_pixel_dist > abs(i - FBO)) {
			nearest_pixel_dist = abs(i - FBO);
		}
	}

	if (count <= 1 && handheld_count <= 1) {
		return vec4(0.0);
	} else if (handheld_count > 1) {
		// if (mix(radius, 0, handheld_value.b/float(handheld_count)/falloff_max_dist_rel) < nearest_pixel_dist*radius/float(FBO)) {
		// 	return vec4(0.0);
		// }
		if (FB_RADIUS_FORMULA(handheld_value, handheld_count) < nearest_pixel_dist*radius/float(FBO)) {
			return vec4(0.0);
		}

		return handheld_value / float(handheld_count);
	} else {
		// if (mix(radius, 0, value.b/float(count)/falloff_max_dist_rel) < nearest_pixel_dist*radius/float(FBO)) {
		// 	return vec4(0.0);
		// }
		if (FB_RADIUS_FORMULA(value, count) < nearest_pixel_dist*radius/float(FBO)) {
			return vec4(0.0);
		}

		return value/float(count);
	}
}

#endif