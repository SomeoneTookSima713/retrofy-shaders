#ifndef FX_VERT_SNAPPING
#define FX_VERT_SNAPPING

#include "/effects/options.glsl"

vec3 snap_vertex(vec3 vertex, float proj_vertex_z, float precision_mult) {
    float prec = mix(PSX_VERTS_NEAR_PRECISION, PSX_VERTS_FAR_PRECISION, clamp(proj_vertex_z/PSX_VERTS_PRECISION_FALLOFF_DIST, 0.0, 1.0)) * precision_mult;
    return floor(vertex * prec) / prec;
}

vec4 ftransform_snapped(vec4 glvertex, mat4x4 model_view_mat, mat4x4 projection_mat, float precision_mult) {
    vec4 vert_world = model_view_mat * glvertex;
	vert_world.xyz = snap_vertex(vert_world.xyz, (projection_mat * vert_world).z, precision_mult);
    
    // vec4 vert_world_unsnapped = model_view_mat * glvertex;
    // vec4 vert_world = vec4(
    //     mat3(model_view_mat) * glvertex.xyz + snap_vertex(model_view_mat[3].xyz, (projection_mat * vert_world_unsnapped).z, precision_mult),
    //     dot(vec4(model_view_mat[0][3],model_view_mat[1][3],model_view_mat[2][3],model_view_mat[3][3]), glvertex)
    // );


    return projection_mat * vert_world;
    // return vert_world;
}

#endif