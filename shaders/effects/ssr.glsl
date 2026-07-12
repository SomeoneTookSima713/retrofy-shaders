// Screen-Space Raytracing
#ifndef FX_SSR
#define FX_SSR

struct SSRMats {
    mat4 proj_mat;
    mat4 inv_proj_mat;
    mat4 model_view_mat;
};

#define SSRMATS_DEFAULT_CONSTRUCTOR SSRMats(gbufferProjection, gbufferProjectionInverse, gbufferModelView)

#define SSR_ERR_NONE 0 // No error
#define SSR_ERR_HIT_NORMAL_MISMATCH 2 // When the face normal at the hit pixel doesn't face the ray
#define SSR_ERR_OUT_OF_SCREEN 3
#define SSR_ERR_ITERATIONS_EXCEEDED 4

struct SSRResult {
    int error_code;
    vec3 hit_uvw;
    vec3 viewspace_hit_dir;
};

#define SSRRESULT_ERR(code, viewspace_hit_dir) SSRResult(code, vec3(-1.0), viewspace_hit_dir)
#define SSRRESULT_OK(uv, viewspace_hit_dir) SSRResult(0, uv, viewspace_hit_dir)

vec3 ssr_screen_to_view(vec3 screen_space, SSRMats mats) {
    vec4 view_w = mats.inv_proj_mat * vec4(screen_space * 2.0 - 1.0, 1.0);
    return view_w.xyz / view_w.w;
}

vec3 ssr_view_to_screen(vec3 view_space, SSRMats mats) {
    vec4 screen_w = mats.proj_mat * vec4(view_space, 1.0);
    return screen_w.xyz / screen_w.w * 0.5 + 0.5;
}

vec3 ssr_project_and_divide(vec3 vec, mat4 mat) {
    vec4 res = mat * vec4(vec, 1.0);
    return res.xyz / res.w;
}

bool ssr_trace_depthtex_mipmapped(vec3 clipspace_start, vec3 clipspace_dir, float max_len, vec2 view_size, sampler2D depthtex, int mipmap, float epsilon, out vec3 clipspace_hit, out float ray_pixel_intersect_len) {
    const int max_steps = 8;
    
    vec2 mipmap_size = view_size / float(1 << mipmap);

    vec2 txpos_intermediate = clipspace_start.xy * mipmap_size;
    ivec2 texelspace_pos = ivec2(txpos_intermediate);
    vec2 txpos_delta = fract(txpos_intermediate);
    float curr_depth = clipspace_start.z;

    for (int i = 0; i < max_steps; i++) {
        float texel_depth = texelFetch(depthtex, texelspace_pos, mipmap).r;

        if (curr_depth - texel_depth >= 0.0 && curr_depth - texel_depth <= epsilon) {
            clipspace_hit = vec3((vec2(texelspace_pos) + txpos_delta) / mipmap_size, curr_depth);
            ray_pixel_intersect_len = dot(txpos_delta, clipspace_dir.xy);
            return true;
        } else {
            txpos_delta += clipspace_dir.xy;
            curr_depth += clipspace_dir.z;
            texelspace_pos += ivec2(txpos_delta);
            txpos_delta = fract(txpos_delta);
        }
    }

    return false;
}

// Requires mipmaps of the depthtex and normaltex to exist
// Traces clipspace to find preexisting screenspace info of the worldspace point that would get hit by the given ray. Uses Mipmaps to accelerate this.
SSRResult ssr_raytrace(vec3 ndcspace_pos, vec3 viewspace_pos, vec3 viewspace_ray_dir, vec2 view_size, sampler2D depthtex, sampler2D normaltex, SSRMats mats) {
    const int max_steps = 16;
    const float steps_recip = 1.0/float(max_steps);
    const float epsilon = 0.004;
    
    vec3 viewspace_ray_end = viewspace_pos + viewspace_ray_dir * 1024.0;
    viewspace_ray_end /= viewspace_ray_end.z < 0.0 ? viewspace_ray_end.z : 1.0;

    vec3 ndcspace_ray_end = ssr_project_and_divide(viewspace_ray_end, mats.proj_mat);

    vec3 ndcspace_ray_dir = normalize(ndcspace_ray_end - ndcspace_pos);

    // Convert to clip space
    vec3 clipspace_pos = ndcspace_pos * 0.5 + 0.5;
    // vec3 clipspace_ray_dir = ndcspace_ray_dir * 0.5 + 0.5;
    vec3 clipspace_ray_dir = ndcspace_ray_dir / max(ndcspace_ray_dir.x, ndcspace_ray_dir.y);

    vec2 ray_max_lens = mix(
        mix(
            (vec2(1.0) - clipspace_pos.xy) / clipspace_ray_dir.xy,
            -clipspace_pos.xy / clipspace_ray_dir.xy, lessThan(clipspace_ray_dir.xy, vec2(0.0))
        ),
        vec2(1000.0),
        equal(clipspace_ray_dir.xy, vec2(0.0))
    );

    float clipspace_ray_len = max(ray_max_lens.x, ray_max_lens.y);

    bool did_hit = false;
    vec3 curr_hit_pos = clipspace_pos;
    float ray_pixel_intersect_len = 0.0;

    for (int m = 5; m > 1; m--) {
        vec3 new_hit_pos;
        float new_ray_pixel_intersect_len;

        bool is_hit = ssr_trace_depthtex_mipmapped(
            curr_hit_pos - clipspace_ray_dir * ray_pixel_intersect_len,
            clipspace_ray_dir,
            clipspace_ray_len,
            view_size,
            depthtex,
            m,
            0.004,
            new_hit_pos,
            new_ray_pixel_intersect_len
        );

        if (is_hit) {
            did_hit = true;
            curr_hit_pos = new_hit_pos;
            ray_pixel_intersect_len = new_ray_pixel_intersect_len;
        } else {
            break;
        }
    }
    
    vec3 normal = ssr_project_and_divide(texture(normaltex, curr_hit_pos.xy).xyz * 2.0 - 1.0, mats.model_view_mat);

    // return did_hit ? ((dot(normal, viewspace_ray_dir) < 0.0 && curr_hit_pos.z < viewspace_pos.z) ? SSRRESULT_OK(curr_hit_pos.xy, viewspace_ray_dir) : SSRRESULT_ERR(SSR_ERR_HIT_NORMAL_MISMATCH, viewspace_ray_dir)) : SSRRESULT_ERR(SSR_ERR_ITERATIONS_EXCEEDED, viewspace_ray_dir);
    return did_hit ? SSRRESULT_OK(curr_hit_pos, viewspace_ray_dir) : SSRRESULT_ERR(SSR_ERR_ITERATIONS_EXCEEDED, viewspace_ray_dir);
}

#endif