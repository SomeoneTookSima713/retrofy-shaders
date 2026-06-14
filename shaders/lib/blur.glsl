#ifndef LIB_BLUR
#define LIB_BLUR

#define UV_CLAMP(val) clamp(val, vec2(0.0), vec2(1.0))

vec4 box_blur_3x3(sampler2D tex, vec2 uv, vec2 texture_size_recip) {
    return (
        texture(tex, uv + vec2(-1,-1) * texture_size_recip) +
        texture(tex, uv + vec2( 0,-1) * texture_size_recip) +
        texture(tex, uv + vec2(+1,-1) * texture_size_recip) +
        texture(tex, uv + vec2(-1, 0) * texture_size_recip) +
        texture(tex, uv + vec2( 0, 0) * texture_size_recip) +
        texture(tex, uv + vec2(+1, 0) * texture_size_recip) +
        texture(tex, uv + vec2(-1,+1) * texture_size_recip) +
        texture(tex, uv + vec2( 0,+1) * texture_size_recip) +
        texture(tex, uv + vec2(+1,+1) * texture_size_recip)
    ) / 9;
}

vec4 box_blur_dyn(sampler2D tex, vec2 uv, vec2 texture_size_recip, int kernel_sidelen, float kernel_mult) {
    vec4 value = vec4(0.0);

    float offset = kernel_sidelen/2;
    for (int i=0; i<kernel_sidelen*kernel_sidelen; i++) {
		vec4 c = texture(tex, UV_CLAMP(uv + vec2(i%kernel_sidelen - offset, i/kernel_sidelen - offset) * kernel_mult * texture_size_recip));
		#ifdef LIB_BLUR_CONF_GLINT_EXTRAS
			c.r = ceil(c.r);
		#endif
        value += c;
    }

    return value / (kernel_sidelen*kernel_sidelen);
}

vec3 box_blur_dyn_weighted_rgb(sampler2D tex, vec2 uv, vec2 texture_size_recip, int kernel_sidelen, float kernel_mult) {
    vec3 value = vec3(0.0);

    float offset = kernel_sidelen/2;
    float count = 0.0;
    for (int i=0; i<kernel_sidelen*kernel_sidelen; i++) {
        vec4 col = texture(tex, UV_CLAMP(uv + vec2(i%kernel_sidelen - offset, i/kernel_sidelen - offset) * kernel_mult * texture_size_recip));
        value += col.rgb * col.a;
        count += col.a;
    }

    return value / count;
}

const int fancy_blur_samples = 7;
const int fancier_blur_samples = 9;
const int fancy_blur_offset = fancier_blur_samples / 2 - 1;
const int fancier_blur_offset = fancier_blur_samples / 2 - 1;

#define FBS fancy_blur_samples
#define FBO fancy_blur_offset
#define FB_RADIUS_FORMULA(VAL,COUNT) radius*falloff_max_dist/(VAL.b/float(COUNT)*(far-near))
vec4 fancy_ceiling_box_blur_x(sampler2D mask, vec2 uv, vec2 view_size, float radius, float falloff_max_dist, float near, float far) {
	vec4 currval = texture(mask, uv);
	if (currval.r >= 0.5) {
		return currval;
	}

	vec4 value = vec4(0.0);
	vec4 handheld_value = vec4(0.0);
	int count = 0;
	int handheld_count = 0;
	int nearest_pixel_dist = 1000;
	for (int i=0; i<FBS; i++) {
		vec4 maskval = texture(mask, UV_CLAMP(uv + vec2(i - FBO, 0)/FBO*radius/view_size));
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

vec4 fancy_ceiling_box_blur_y(sampler2D mask, vec2 uv, vec2 view_size, float radius, float falloff_max_dist, float near, float far) {
	vec4 currval = texture(mask, uv);
	if (currval.r >= 0.5) {
		return currval;
	}

	vec4 value = vec4(0.0);
	vec4 handheld_value = vec4(0.0);
	int count = 0;
	int handheld_count = 0;
	int nearest_pixel_dist = 1000;
	for (int i=0; i<FBS; i++) {
		vec4 maskval = texture(mask, UV_CLAMP(uv + vec2(0, i - FBO)/FBO*radius/view_size));
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

#undef FBS
#undef FBO
#undef FB_RADIUS_FORMULA
#define FBS fancier_blur_samples
#define FBO fancier_blur_offset
vec4 fancier_ceiling_box_blur_x(sampler2D color, sampler2D mask, vec2 uv, vec2 view_size, float radius) {
	vec4[FBS] values;
	vec4[FBS] maskvals;
	vec4 avg = vec4(0.0);
	for (int i=0; i<FBS; i++) {
		// values[i] = texture(color, uv + vec2(i%FBS - FBO, i/FBS - FBO)/FBO*radius/view_size);
		// maskvals[i] = texture(mask, uv + vec2(i%FBS - FBO, i/FBS - FBO)/FBO*radius/view_size);
		values[i] = texture(color, UV_CLAMP(uv + vec2(i - FBO, 0)/FBO*radius/view_size));
		maskvals[i] = texture(mask, UV_CLAMP(uv + vec2(i - FBO, 0)/FBO*radius/view_size));
		avg += values[i];
	}
	avg /= FBS;

	vec4 nearest_col;
	float nearest_dist = 1000.0;
	float nearest_depth = 0;
	for (int i=0; i<FBS; i++) {
		float d = distance(values[i], avg);
		if (d < nearest_dist && values[i].a > 0.5 && maskvals[i].r > 0.1) {
			nearest_col = values[i];
			nearest_dist = d;
		}
	}

	return nearest_col;
}

vec4 fancier_ceiling_box_blur_y(sampler2D color, sampler2D mask, vec2 uv, vec2 view_size, float radius) {
	vec4[FBS] values;
	vec4[FBS] maskvals;
	vec4 avg = vec4(0.0);
	for (int i=0; i<FBS; i++) {
		// values[i] = texture(color, uv + vec2(i%FBS - FBO, i/FBS - FBO)/FBO*radius/view_size);
		// maskvals[i] = texture(mask, uv + vec2(i%FBS - FBO, i/FBS - FBO)/FBO*radius/view_size);
		values[i] = texture(color, UV_CLAMP(uv + vec2(0, i - FBO)/FBO*radius/view_size));
		maskvals[i] = texture(mask, UV_CLAMP(uv + vec2(0, i - FBO)/FBO*radius/view_size));
		avg += values[i];
	}
	avg /= FBS;

	vec4 nearest_col;
	float nearest_dist = 1000.0;
	for (int i=0; i<FBS; i++) {
		float d = distance(values[i], avg);
		if (d < nearest_dist  && values[i].a > 0.5 && maskvals[i].r > 0.1) {
			nearest_col = values[i];
			nearest_dist = d;
		}
	}

	return nearest_col;
}
#undef FBS
#undef FBO

#endif