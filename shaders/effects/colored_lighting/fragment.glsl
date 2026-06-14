#ifndef FX_CLH_FRAGMENT
#define FX_CLH_FRAGMENT

// Dependencies
#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/pixelation.glsl"

// Fragment shader inputs
in vec3 block_centered_relative_pos;
in vec3 relative_pos;
in vec4 blocklight;

#ifdef DITHER_LIGHTING
	in vec2 surface_tangent_world_pos;
#endif

// Functionality
vec3 colored_lighting_get_blocklight(vec2 lmcoord, vec2 pixelation_texel_offset) {
    float volume_edge_distance_min = VOXEL_AREA_RADIUS - max(abs(relative_pos.x - VOXEL_AREA_RADIUS), max(abs(relative_pos.y - VOXEL_AREA_RADIUS), abs(relative_pos.z - VOXEL_AREA_RADIUS)));
	
	return mix_colors(BLOCKLIGHT_COLOR * pow(lmcoord.x, 1.2), texel_snap(blocklight.rgb, pixelation_texel_offset), clamp((volume_edge_distance_min-16.0)*0.125, 0.0, 1.0));
}

#endif