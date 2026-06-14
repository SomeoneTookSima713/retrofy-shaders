#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/vertex_snapping.glsl"
#include "/lib/voxelization_encoding.glsl"

#define CLH_SAFE_MODE
#define CLH_MANUAL_POS_ATTRIBS
// #define IMPL_DITHER
#include "/effects/colored_lighting/vertex.glsl"

uniform int currentRenderedItemId;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform vec3 relativeEyePosition;

uniform int frameCounter;
uniform vec3 previousCameraPositionFract;
uniform vec3 cameraPositionFract;

uniform ivec2 atlasSize;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out vec3 normal;
flat out int item_id;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	normal = gl_Normal;
	float light_value;
	if (gl_Position.x / gl_Position.w < 0.0) {
		item_id = heldItemId2;
		light_value = heldBlockLightValue2;
	} else {
		item_id = heldItemId;
		light_value = heldBlockLightValue;
	}

	block_centered_relative_pos = cameraPositionFract;
	relative_pos = cameraPositionFract + VOXEL_AREA_RADIUS;

	colored_lighting_compute_vertex_outputs_general(normal, cameraPositionFract, previousCameraPositionFract, frameCounter);
	#ifndef DO_COLORED_LIGHTING
		blocklight_color = BLOCKLIGHT_COLOR;
	#endif

	// TODO: Do my new implementation for entity colored lighting
}