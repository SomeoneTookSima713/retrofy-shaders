#version 430 compatibility

#include "/effects/options.glsl"

/*
const int colortex3Format = RGBA16F;
const int colortex5Format = RGB32F;
const int colortex8Format = RGBA32F;
const int colortex13Format = RG32F;
const int colortex15Format = R32F;
const bool colortex13Clear = false;
const bool colortex14Clear = false;
const vec4 colortex15ClearColor = vec4(10000.0, 0.0, 0.0, 1.0);
*/

#ifdef FULL_SHADOW_PASS
    const float shadowDistanceRenderMul = 1.0;
    #if VOXEL_AREA_SIZE == 256
        const float shadowDistance = 256.0;
        const float voxelDistance = 256.0;
    #elif VOXEL_AREA_SIZE == 192
        const float shadowDistance = 192.0;
        const float voxelDistance = 192.0;
    #elif VOXEL_AREA_SIZE == 128
        const float shadowDistance = 128.0;
        const float voxelDistance = 128.0;
    #endif
#else
    const float shadowDistanceRenderMul = 1.0;
    const float shadowDistance = 16.0;
    const float voxelDistance = 16.0;
#endif
const int shadowMapResolution = 8;

#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/dither.glsl"
#include "/lib/blur.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
#if defined DISTANT_HORIZONS
	uniform sampler2D dhDepthTex0;
	uniform sampler2D dhDepthTex1;
#elif defined VOXY
	uniform sampler2D vxDepthTexOpaque;
	uniform sampler2D vxDepthTexTrans;
#endif

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform bool isEyeInWater;

uniform mat4 gbufferProjectionInverse;

uniform float fogEnd;

in vec2 texcoord;

in vec2 main_reduced_view_size;
in vec2 hand_reduced_view_size;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 get_viewspace_position(vec2 texcoord, float depth, mat4x4 projection_mat_inverse) {
    vec3 clipSpace = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewW = projection_mat_inverse * vec4(clipSpace, 1.0);
    return viewW.xyz / viewW.w;
}

float fog_mode_to_float(int fog_mode) {
	if (fog_mode == 2048) {
		return 0.0;
	} else if (fog_mode == 2049) {
		return 0.33;
	} else if (fog_mode == 9729) {
		return 0.66;
	} else {
		return 1.0;
	}
}

void main() {
	vec2 view_size = vec2(viewWidth, viewHeight);

	color = texture(colortex0, floor(texcoord * main_reduced_view_size) / main_reduced_view_size + vec2(0.5)/view_size);
	// if (!is_glint_outline(texcoord, colortex5, depthtex0, view_size, int(view_size.y/main_reduced_view_size.y)*3+1, gbufferProjectionInverse)) {
	// 	vec4 handcol = texture(colortex4, floor(texcoord * hand_reduced_view_size) / hand_reduced_view_size + vec2(0.5)/view_size);
	// 	color = mix(color, handcol, handcol.a);
	// }
	vec4 handcol = texture(colortex4, floor(texcoord * hand_reduced_view_size) / hand_reduced_view_size + vec2(0.5)/view_size);
	color = mix(color, handcol, handcol.a);

	#ifdef NETHER
		if (isEyeInWater) {
			color.rgb *= FINAL_IMAGE_UNDERLAVA_COLOR_MULT;
		}
	#else
		if (isEyeInWater) {
			if (fogEnd < 2.0) {
				color.rgb *= FINAL_IMAGE_UNDERLAVA_COLOR_MULT;
			} else {
				color.rgb *= FINAL_IMAGE_UNDERWATER_COLOR_MULT;
			}
		}
	#endif

	
	vec3 hsv = rgb2hsv(color.rgb);

	hsv.z = pow(hsv.z, 0.95);

	// vec3 hsv = color.rgb;

	vec3 lower_posterized = floor(hsv * FINAL_IMAGE_COLOR_AMOUNT) / FINAL_IMAGE_COLOR_AMOUNT;
	vec3 upper_posterized = ceil(hsv * FINAL_IMAGE_COLOR_AMOUNT) / FINAL_IMAGE_COLOR_AMOUNT;

	#if FINAL_IMAGE_STYLE == FINAL_IMAGE_STYLE_TRUECOLOR
		vec3 final_hsv = hsv;
	#elif FINAL_IMAGE_STYLE == FINAL_IMAGE_STYLE_POSTERIZED
		vec3 final_hsv = lower_posterized;
	#else
		vec3 dist_lower = abs(hsv - lower_posterized);
		vec3 dist_bounds = abs(upper_posterized - lower_posterized);
		vec3 dist = dist_lower / dist_bounds;
		dist = sign(dist - 0.5)*clamp(abs(dist - 0.5) / (1.0 - FINAL_IMAGE_DITHERING_REDUCTION), 0.0, 0.5) + 0.5;

		vec3 dither_mult = dither4x4(floor(texcoord * main_reduced_view_size), dist);

		vec3 final_hsv = mix(lower_posterized, upper_posterized, dither_mult);
	#endif

	color.rgb = hsv2rgb(final_hsv);

	#if DEBUG_DISPLAY_TEXTURE != -1
		#if DEBUG_DISPLAY_TEXTURE == -2
			#define DDT depthtex0
		#elif DEBUG_DISPLAY_TEXTURE == -3
			#define DDT depthtex1
		#elif DEBUG_DISPLAY_TEXTURE == -4 && defined DISTANT_HORIZONS
			#define DDT dhDepthTex0
		#elif DEBUG_DISPLAY_TEXTURE == -5 && defined DISTANT_HORIZONS
			#define DDT dhDepthTex1
		#elif DEBUG_DISPLAY_TEXTURE == -4 && defined VOXY
			#define DDT vxDepthTexOpaque
		#elif DEBUG_DISPLAY_TEXTURE == -5 && defined VOXY
			#define DDT vxDepthTexTrans
		#elif DEBUG_DISPLAY_TEXTURE == 0
			#define DDT colortex0
		#elif DEBUG_DISPLAY_TEXTURE == 1
			#define DDT colortex1
		#elif DEBUG_DISPLAY_TEXTURE == 2
			#define DDT colortex2
		#elif DEBUG_DISPLAY_TEXTURE == 3
			#define DDT colortex3
		#elif DEBUG_DISPLAY_TEXTURE == 4
			#define DDT colortex4
		#elif DEBUG_DISPLAY_TEXTURE == 5
			#define DDT colortex5
		#elif DEBUG_DISPLAY_TEXTURE == 6
			#define DDT colortex6
		#elif DEBUG_DISPLAY_TEXTURE == 7
			#define DDT colortex7
		#elif DEBUG_DISPLAY_TEXTURE == 8
			#define DDT colortex8
		#elif DEBUG_DISPLAY_TEXTURE == 9
			#define DDT colortex9
		#elif DEBUG_DISPLAY_TEXTURE == 10
			#define DDT colortex10
		#elif DEBUG_DISPLAY_TEXTURE == 11
			#define DDT colortex11
		#elif DEBUG_DISPLAY_TEXTURE == 12
			#define DDT colortex12
		#elif DEBUG_DISPLAY_TEXTURE == 13
			#define DDT colortex13
		#elif DEBUG_DISPLAY_TEXTURE == 14
			#define DDT colortex14
		#elif DEBUG_DISPLAY_TEXTURE == 15
			#define DDT colortex15
		#endif
		color = texture(DDT, texcoord);
	#endif

	// color.rgb = mix(lower_posterized, upper_posterized, dither_mult);
	// color = texture(colortex0, texcoord);
	// color = texture(colortex4, texcoord);
	// color = texture(colortex3, texcoord);
	// color = texture(colortex5, texcoord);
	// color.rgb = vec3(texture(colortex5, texcoord).a-1.0, 0.0, 0.0);
	// color.rgb *= texture(colortex5, texcoord).r;
	// color = texture(colortex6, texcoord) * 0.8 + texture(colortex5, texcoord).rrrr * 0.2;
	// color = texture(colortex7, texcoord);
	// color = texture(colortex8, texcoord);
	// color = texture(colortex9, texcoord);
	// color = texture(colortex12, texcoord);
	// color = vec4(texture(dhDepthTex0, texcoord).r, 0.0, 0.0, 1.0);

	// color = vec4((texture(vxDepthTexOpaque, texcoord).r - texture(vxDepthTexTrans, texcoord).r)*100.0, 0.0, 0.0, 1.0);

	// color = vec4(is_zooming, 0.0, 0.0, 1.0);

	// int screen_res_mult = int(viewHeight / main_reduced_view_size.y);
	// vec3 current_pixel_pos = get_viewspace_position(texcoord, texture(depthtex0, texcoord).r, gbufferProjectionInverse);
	// color.rgb = vec3(box_blur_dyn(colortex9, floor(texcoord*floor(view_size/screen_res_mult))/floor(view_size/screen_res_mult)+vec2(0.5,0.5)/view_size, vec2(1.0)/view_size, 5, -screen_res_mult*16).r, 0.0, 0.0);
	
	// color.rgb = vec3(box_blur_dyn(colortex5, texcoord, vec2(1.0)/view_size, int(view_size.y/main_reduced_view_size.y)*1+1).r*5.0, 0.0, 0.0);
	// if (is_glint_outline(texcoord, colortex5, depthtex0, view_size, int(view_size.y/main_reduced_view_size.y)*4+1)) {
	// 	color.rgb = vec3(1.0, 0.0, 0.0);
	// }
	// color.rgb = vec3(go_linearize_depth(texture(depthtex0, texcoord).r, near, far)*2, 0.0, 0.0);

	// color.rgb = vec3(hand_reduced_view_size.x / 1920, hand_reduced_view_size.y / 1080, 0.0);
}