#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/ssao.glsl"
#include "/effects/enchantment_glint.glsl"
#include "/lib/blur.glsl"
#include "/lib/blur_but_texel_fetch.glsl"
// #include "/lib/blur_but_go_vroom.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex10;
// uniform sampler2D colortex6;
// uniform sampler2D colortex9;

// uniform mat4 gbufferModelView;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferProjection;
// uniform mat4 gbufferProjectionInverse;

// uniform float near;
// uniform float far;

uniform float viewWidth;
uniform float viewHeight;

// in vec2 texcoord;
// flat in int screen_res_mult;

/*
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
const bool colortex9MipmapEnabled = true;
const bool colortex10MipmapEnabled = true;
*/

#ifdef DEBUG_DISABLE_ENCHANTMENT_EFFECT
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 nullvec;
#else
/* RENDERTARGETS: 5,6,9,10 */
layout(location = 0) out uvec4 out_colortex5;
layout(location = 1) out vec4 out_colortex6;
layout(location = 2) out vec4 out_colortex9;
layout(location = 3) out vec4 out_colortex10;
// layout(location = 3) out vec4 out_colortex0;
#endif

void main() {
    #ifdef DEBUG_DISABLE_ENCHANTMENT_EFFECT
    nullvec = texture(colortex0, gl_FragCoord.xy  / vec2(viewWidth, viewHeight));
    #else
	out_colortex9.r = blur_glint_depth(ivec2(gl_FragCoord.xy), colortex9, 6, 1, false);
    out_colortex5.r = blur_glint_mask(ivec2(gl_FragCoord.xy), colortex5, 4, 2, false);
    out_colortex5.r |= bool(texelFetch(colortex5, ivec2(gl_FragCoord.xy), 0).r & 1u) ? 4u : 0u;
    
    out_colortex6 = vec4(blur_glint_color(ivec2(gl_FragCoord.xy), colortex6, colortex5, 6, false), 1.0);
    out_colortex10 = box_blur_7x7_x(colortex10, ivec2(gl_FragCoord.xy) >> ivec2(2), 2);
    #endif
}