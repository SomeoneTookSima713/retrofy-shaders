#version 450 compatibility

#include "/effects/enchantment_glint.glsl"
#include "/lib/adam_colors.glsl"
#include "/lib/pixelation.glsl"

uniform sampler2D gtexture;
// uniform sampler2D colortex5;
// layout(rgba32f) uniform image2D colorimg5;

uniform int currentRenderedItemId;

uniform float alphaTestRef = 0.1;

uniform float near;
uniform float far;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferProjection;

in vec2 texcoord;
in vec4 color;
in float world_space_dist;

/* RENDERTARGETS: 5,9 */
layout(location = 0) out uvec4 out_colortex5;
layout(location = 1) out vec4 out_colortex9;
// layout(location = 2) out vec4 out_colortex0;

float linearize_depth(float depth, float near_plane, float far_plane) 
{
    float z = depth * 2.0 - 1.0; // back to NDC 
    return ((2.0 * near_plane * far_plane) / (far_plane + near_plane - z * (far_plane - near_plane)));
}

void main() {
    vec4 colortex0 = texture(gtexture, texcoord) * color;
	// colortex0 = vec4(imageLoad(colorimg5, ivec2(int(texcoord.x*viewWidth), int(texcoord.y*viewHeig))).r, 0.0, 0.0, 1.0);
	// colortex0.a *= 
	if (colortex0.a < alphaTestRef) {
		discard;
	}

	// colortex4 = vec4(0.0,0.0,0.0,0.0);
	// out_colortex5 = vec4(1.0, 0.0, linearize_depth(gl_FragCoord.z, near, far), 1.0);
    // out_colortex5.r = float(encode_glint_mask(true, gl_ProjectionMatrix != gbufferProjection)) / 255.0;
    out_colortex5.r = encode_glint_mask(true, gl_ProjectionMatrix != gbufferProjection, SRGB_LUMA(colortex0.rgb) * 2.0);
	// out_colortex5 = vec4(1.0, 0.0, gl_FragCoord.z, 1.0);
	// out_colortex5 = vec4(0.0, 0.0, 0.0, 0.0);
	// out_colortex5 = texture(colortex5, texcoord);
	out_colortex9.r = abs(world_space_dist);
    // out_colortex0 = vec4(out_colortex9.r * 0.01, 0.0, 0.0, 1.0);
    // out_colortex0 = vec4(float(true), float(gl_ProjectionMatrix != gbufferProjection), 0.0, 1.0);
    // out_colortex0 = vec4(float(out_colortex5.r) * 0.5, 0.0, 0.0, 1.0);
}