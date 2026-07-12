#version 430 compatibility

#define LIB_BLUR_CONF_GLINT_EXTRAS
#include "/effects/options.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/effects/enchantment_glint.glsl"
// #include "/lib/blur.glsl"
#include "/lib/colors.glsl"
#include "/lib/unified_depth.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex4; // hand
// uniform usampler2D colortex5; // glint mask
// uniform sampler2D colortex6; // glint colors
uniform sampler2D colortex7; // normals
// uniform sampler2D colortex9; // glint depth
uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

in vec2 texcoord;
// flat in int screen_res_mult;
// flat in float glint_mult_add;

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 out_colortex4;

float linearize_depth(float depth, float near_plane, float far_plane) 
{
    float z = depth * 2.0 - 1.0; // back to NDC 
    return ((2.0 * near_plane * far_plane) / (far_plane + near_plane - z * (far_plane - near_plane))) / far_plane;	
}

vec3 get_viewspace_position(vec2 texcoord, float depth, mat4x4 projection_mat_inverse) {
    vec3 clipSpace = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewW = projection_mat_inverse * vec4(clipSpace, 1.0);
    return viewW.xyz / viewW.w;
}

void main() {
	color = texture(colortex0, texcoord);
    out_colortex4 = texture(colortex4, texcoord);

    vec2 view_size = vec2(viewWidth, viewHeight);

    float depth = texture(depthtex0, texcoord).r;

    vec3 current_pixel_pos = get_viewspace_position(texcoord, depth, gbufferProjectionInverse);
    vec3 normal_translated_pos = current_pixel_pos + vec3(1.0, 0.0, 0.0);
    vec4 cpp_clip = gbufferProjection * vec4(current_pixel_pos, 1.0);
    vec4 ntp_clip = gbufferProjection * vec4(normal_translated_pos, 1.0);
    float radius_base = distance(ntp_clip.xyz, cpp_clip.xyz);

    bool is_glint, is_gbuffers_hand, is_unblurred;
    float enchantment_effect_luma;
    read_and_decode_glint_mask(ivec2(gl_FragCoord.xy), is_glint, is_gbuffers_hand, is_unblurred, enchantment_effect_luma);

    float mask_depth = texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).r;

    vec4 view_w = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    float image_depth = abs(view_w.z / view_w.w);

    vec3 glintcol = texture(colortex6, texcoord).rgb;
    glintcol = rgb2hsv(glintcol);
    vec3 glintcol_inner = glintcol;
    
    // glintcol.x = mod(glintcol.x+0.05,1.0);
    glintcol.y *= 1.1;
    glintcol.z = clamp(glintcol.z, 0.3, 1.0) * 2.0;
    glintcol_inner.y *= 1.5;
    glintcol_inner.z = clamp(glintcol_inner.z, 0.2, 1.0) * 1.5;

    glintcol = clamp(hsv2rgb(glintcol), vec3(0.0), vec3(1.0));
    glintcol_inner = clamp(hsv2rgb(glintcol_inner), vec3(0.0), vec3(1.0));
    if (is_glint && (mask_depth < image_depth + 0.05 || is_gbuffers_hand) && !is_unblurred && mask_depth < 12.0) {
        color.rgb = mix(color.rgb, glintcol, GLINT_OUTLINE_OPACITY);
    }
    // color.rgb = vec3(float(is_glint), float(is_gbuffers_hand), 0.0);
    // color.rgb = vec3(float(texelFetch(colortex5, ivec2(gl_FragCoord.xy), 0).r)*0.5, 0.0, 0.0);
    else if (
        is_glint && (mask_depth < image_depth + 0.05 || is_gbuffers_hand) && is_unblurred
    ) {
        color.rgb = mix(color.rgb, glintcol, enchantment_effect_luma / 2.0 + 0.05);
        if (out_colortex4.a > 0.01) {
            // out_colortex4.rgb = mix(out_colortex4.rgb, (GLINT_OVERLAY_COLOR).rgb, (GLINT_OVERLAY_COLOR).a);
            // out_colortex4.rgb = mix(out_colortex4.rgb, glintcol, 1-glint_mult);
            out_colortex4.rgb = mix(out_colortex4.rgb, glintcol, enchantment_effect_luma / 2.0 + 0.05);
        }
    }
}