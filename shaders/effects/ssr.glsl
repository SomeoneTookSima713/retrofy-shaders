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
    vec2 hit_uv;
    vec3 viewspace_hit_dir;
};

#define SSRRESULT_ERR(code, viewspace_hit_dir) SSRResult(code, vec2(-1.0), viewspace_hit_dir)
#define SSRRESULT_OK(uv, viewspace_hit_dir) SSRResult(0, uv, viewspace_hit_dir)

vec3 ssr_screen_to_view(vec3 screen_space, SSRMats mats) {
    vec4 view_w = mats.inv_proj_mat * vec4(screen_space * 2.0 - 1.0, 1.0);
    return view_w.xyz / view_w.w;
}

vec3 ssr_view_to_screen(vec3 view_space, SSRMats mats) {
    vec4 screen_w = mats.proj_mat * vec4(view_space, 1.0);
    return screen_w.xyz / screen_w.w * 0.5 + 0.5;
}

SSRResult ssr_raytrace(vec3 viewspace_pos, vec3 ray_dir, sampler2D depthtex, sampler2D normaltex, SSRMats mats) {
    const int max_steps = 16;
    const float steps_recip = 1.0/float(max_steps);
    const float epsilon = 0.004;
    float step_size_small = max(viewspace_pos.z * viewspace_pos.z, 0.25);

    vec3 curr_pos = viewspace_pos;

    vec3 sky_dir = normalize(viewspace_pos + 1000.0*ray_dir);

    float avg_depth_dist = 0.0;

    for (int i = 0; i < max_steps; i++) {
        vec3 uvw = ssr_view_to_screen(curr_pos, mats);

        if (clamp(uvw.xyz, 0.0, 1.0) != uvw.xyz) {
            return SSRRESULT_ERR(SSR_ERR_OUT_OF_SCREEN, sky_dir);
        }

        float actual_depth = texture2D(depthtex, uvw.xy).r;
        vec3 actual_pos = ssr_screen_to_view(vec3(uvw.xy, actual_depth), mats);

        avg_depth_dist += (uvw.z - actual_depth) * steps_recip;

        if (actual_depth - uvw.z < epsilon) {
            vec3 normal = mat3(mats.model_view_mat) * (texture2D(normaltex, uvw.xy).xyz * 2.0 - 1.0);
            if (dot(normal, ray_dir) < 0.0 && dot(actual_pos - viewspace_pos, ray_dir) > 0.0) {
                return SSRRESULT_OK(uvw.xy, normalize(curr_pos));
            } else {
                return SSRRESULT_ERR(SSR_ERR_HIT_NORMAL_MISMATCH, sky_dir);
            }
        }
        curr_pos += (abs(curr_pos.z - actual_pos.z) > abs(viewspace_pos.z*0.5) ? 1.0 : sign(curr_pos.z - actual_pos.z)) * ray_dir * step_size_small;
    }

    if (avg_depth_dist > 20.0) {
        for (int i = 0; i < max_steps; i++) {
            vec3 uvw = ssr_view_to_screen(curr_pos, mats);

            if (clamp(uvw.xyz, 0.0, 1.0) != uvw.xyz) {
                return SSRRESULT_ERR(SSR_ERR_OUT_OF_SCREEN, sky_dir);
            }

            float actual_depth = texture2D(depthtex, uvw.xy).r;
            vec3 actual_pos = ssr_screen_to_view(vec3(uvw.xy, actual_depth), mats);

            if (actual_depth - uvw.z < epsilon) {
                // return SSRRESULT_OK(uvw.xy, normalize(curr_pos));
                vec3 normal = mat3(mats.model_view_mat) * (texture2D(normaltex, uvw.xy).xyz * 2.0 - 1.0);
                if (dot(normal, ray_dir) < 0.0 && dot(actual_pos - viewspace_pos, ray_dir) > 0.0) {
                    return SSRRESULT_OK(uvw.xy, normalize(curr_pos));
                } else {
                    return SSRRESULT_ERR(SSR_ERR_HIT_NORMAL_MISMATCH, sky_dir);
                }
            }
            curr_pos += (abs(curr_pos.z - actual_pos.z) > abs(viewspace_pos.z*0.5) ? 1.0 : sign(curr_pos.z - actual_pos.z)) * ray_dir * avg_depth_dist * 1.33 * steps_recip;
        }
    }

    return SSRRESULT_ERR(SSR_ERR_ITERATIONS_EXCEEDED, sky_dir);
}

#endif