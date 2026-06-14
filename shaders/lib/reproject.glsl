#ifndef LIB_REPROJECT
#define LIB_REPROJECT

struct ReprojectionInfo {
    mat4 model_view_mat;
    mat4 projection_mat;
    mat4 model_view_mat_inv;
    mat4 projection_mat_inv;
    vec3 cam_delta;
};

ReprojectionInfo create_reproj_info(mat4 model_view_mat, mat4 projection_mat, vec3 cam_delta) {
    return ReprojectionInfo(model_view_mat, projection_mat, inverse(model_view_mat), inverse(projection_mat), cam_delta);
}

vec3 reprojected_uv_from_position(vec3 position, ReprojectionInfo reproj_info) {
    vec4 projection = reproj_info.projection_mat * vec4(mat3(reproj_info.model_view_mat) * (position - reproj_info.cam_delta), 1.0);
    projection.xyz /= projection.w;
    vec3 clipSpace = projection.xyz * 0.5 + 0.5;

    return clipSpace.xyz;
}

vec3 reprojected_world_position(vec2 texcoord, float depth, ReprojectionInfo reproj_info) {
    vec3 clipSpace = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewW = reproj_info.projection_mat_inv * vec4(clipSpace, 1.0);
    vec3 viewSpace = viewW.xyz / viewW.w;

    return mat3(reproj_info.model_view_mat_inv) * viewSpace + reproj_info.cam_delta;
}

#endif