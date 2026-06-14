#ifndef LIB_SDF
#define LIB_SDF

float sdf_prim_sphere(vec3 vec_point_to_center, float radius) {
    return length(vec_point_to_center) - radius;
}

float sdf_op_smooth_union(float a, float b, float k) {
    k *= 4.0;
    float h = max(k - abs(a-b), 0.0);
    return min(a, b) - h*h*0.25/k;
}

vec3 sdf_op_orientate(vec3 point, mat4 rot_trans_mat) {
    return (rot_trans_mat * vec4(point, 1.0)).xyz;
}

vec3 sdf_op_sym_xz(vec3 point) {
    point.xz = abs(point.xz);
    return point;
}

vec3 sdf_point_repeat_xz_around(vec3 point, float max_dist_from_origin) {
    point.xz = mod(point.xz + max_dist_from_origin, 2.0*max_dist_from_origin) - max_dist_from_origin;
    return point;
}

vec3 sdf_op_sym_repeat_xz(vec3 point, vec2 xz_center, float xz_extents) {
    vec3 center = vec3(xz_center.x, 0.0, xz_center.y);

    return sdf_op_sym_xz(sdf_point_repeat_xz_around(point - center, xz_extents)) + center;
}

#endif