#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/enchantment_glint.glsl"
// #include "/lib/blur.glsl"
#include "/lib/blur_but_texel_fetch.glsl"
// #include "/lib/blur_but_go_vroom.glsl"

// uniform sampler2D colortex5;
// uniform sampler2D colortex6;
// uniform sampler2D colortex9;

uniform float near;
uniform float far;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;
flat in int screen_res_mult;

/*
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
const bool colortex9MipmapEnabled = true;
*/

/* RENDERTARGETS: 5,6,9 */
layout(location = 0) out uvec4 out_colortex5;
layout(location = 1) out vec4 out_colortex6;
layout(location = 2) out vec4 out_colortex9;
// layout(location = 0) out vec4 out_colortex6;

void main() {
    // out_colortex5 = fancy_ceiling_box_blur_y(colortex5, texcoord, vec2(viewWidth, viewHeight), GLINT_OUTLINE_RADIUS, GLINT_RADIUS_FALLOFF, near, far);
    // out_colortex5 = fancy_ceiling_box_blur_y(colortex5, ivec2(gl_FragCoord.xy), ivec2(viewWidth, viewHeight), GLINT_OUTLINE_RADIUS, GLINT_RADIUS_FALLOFF, near, far);
    // out_colortex5 = texelFetch(colortex5, ivec2(gl_FragCoord.xy), 0);
    
    out_colortex9.r = blur_glint_depth(ivec2(gl_FragCoord.xy), colortex9, 6, 1, true);
    out_colortex5.r = blur_glint_mask(ivec2(gl_FragCoord.xy), colortex5, 4, 2, true);
    // out_colortex5.r = blur_glint_mask(ivec2(gl_FragCoord.xy), colortex5, clamp(int(4.0 * near / out_colortex9.r), 0, 16), 2, true);
    out_colortex5.r |= bool(texelFetch(colortex5, ivec2(gl_FragCoord.xy), 0).r & 4u) ? 4u : 0u;
    out_colortex6 = vec4(blur_glint_color(ivec2(gl_FragCoord.xy), colortex6, colortex5, 6, true), 1.0);
    // out_colortex6 = vec4(blur_glint_color(ivec2(gl_FragCoord.xy), colortex6, colortex5, clamp(int(6.0 * near / out_colortex9.r), 0, 18), true), 1.0);

    // out_colortex5 = vec4(ceil(vroom_box_blur_y_rg(colortex5, texcoord, int(GLINT_OUTLINE_RADIUS - 1), viewHeight)-0.1), texture2D(colortex5, texcoord).ba);
    // out_colortex5 = texture(colortex5, texcoord);
    // out_colortex6 = fancier_ceiling_box_blur_y(colortex6, colortex5, texcoord, vec2(viewWidth, viewHeight), GLINT_OUTLINE_RADIUS+2.0);
    // out_colortex6 = texture2D(colortex6, texcoord) * out_colortex5.r;
    
    // out_colortex6 = vroom_masked_box_blur_y(colortex6, colortex5, texcoord, int(GLINT_OUTLINE_RADIUS + 1), viewHeight);
    
	// if (box_blur_dyn(colortex9, texcoord, vec2(1.0)/vec2(viewWidth, viewHeight),int(GLINT_OUTLINE_RADIUS),1.0).g > 0.0001) {
	// 	out_colortex9 = vec4(1.0, 1.0, 0.0, 1.0);
	// }
}