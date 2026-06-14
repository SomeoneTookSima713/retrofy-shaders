#version 430 compatibility

#include "/effects/vertex_snapping.glsl"

uniform int heldItemId;
uniform int heldItemId2;

uniform mat4 gbufferProjection;

out vec2 texcoord;
out vec4 color;
out float world_space_dist;

bool is_holding_highprec_item(vec4 projected_vertex_pos) {
	if (projected_vertex_pos.x / projected_vertex_pos.w < 0.0) {
		return heldItemId2 == 70;
	} else {
		return heldItemId == 70;
	}
}

void main() {
	// if (gl_ProjectionMatrix != gbufferProjection && !is_holding_highprec_item(ftransform())) {
	// 	gl_Position = ftransform_snapped(gl_Vertex, gl_ModelViewMatrix, gl_ProjectionMatrix, 1.0);
	// } else {
	// }
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	world_space_dist = (gl_ModelViewMatrix * gl_Vertex).z;

}