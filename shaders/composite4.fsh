#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/ssr.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/effects/volumetric_clouds.glsl"
#include "/lib/colors.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex7;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;

uniform vec3 cameraPosition;

uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

uniform vec3 cameraPositionFract;
uniform vec3 previousCameraPositionFract;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float sunAngle;
uniform float wetness;
uniform float rainStrength;
uniform float thunderStrength;

uniform bool isEyeInWater;

uniform ivec2 eyeBrightness;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

uniform int worldTime;
uniform int worldDay;

in vec2 texcoord;
flat in int screen_res_mult;

/* RENDERTARGETS: 0,13,14 */
layout(location = 0) out vec4 out_colortex0;
layout(location = 1) out vec4 out_colortex13;
layout(location = 2) out vec4 out_colortex14;

vec3 screen_to_world(vec3 uvw) {
    vec4 view_w = gbufferProjectionInverse * vec4(uvw * 2.0 - 1.0, 1.0);
    vec4 world_w = gbufferModelViewInverse * vec4(view_w.xyz / view_w.w, 1.0);
    return world_w.xyz / world_w.z + cameraPosition;
}

vec3 view_to_world(vec3 view) {
    vec4 world_w = gbufferModelViewInverse * vec4(view, 1.0);
    return world_w.xyz / world_w.w;
}

vec3 world_to_view(vec3 world) {
    vec4 view_w = gbufferModelView * vec4(world - cameraPosition, 1.0);
    return view_w.xyz / view_w.w;
}

void main() {
    out_colortex0 = texture(colortex0, texcoord);
    float curr_depth = texture(depthtex0, texcoord).r;
    float curr_depth_opaque = texture(depthtex1, texcoord).r;

    SSRMats mats = SSRMATS_DEFAULT_CONSTRUCTOR;

    // #define BETA_VOLUMETRIC_CLOUDS
    #ifdef BETA_VOLUMETRIC_CLOUDS
        const float cloud_voxel_size = 2.0;
        const int max_occlusion_steps = 256;
        const float max_occlusion_dist = 8.0;
        const float max_occlusion = 0.95;
        const float sdf_min_y = 104.0;
        const float sdf_max_y = sdf_min_y + vcbve_float;
        const float lod_distance_step = 96.0;

        // TODO: correctly implement DDA
        vec3 target_point = ssr_screen_to_view(vec3(texcoord, curr_depth), mats);
        vec3 ray_dir = mat3(gbufferModelViewInverse) * normalize(target_point);
        vec3 world_sun_dir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        target_point = view_to_world(target_point);
        
        vec3 ray_pos = cameraPosition;
        float initial_inc_len = 1.0;
        if (ray_pos.y < sdf_min_y) {
            initial_inc_len = max(initial_inc_len, (sdf_min_y - ray_pos.y) / abs(ray_dir.y));
        } else if (ray_pos.y > sdf_max_y) {
            initial_inc_len = max(initial_inc_len, (ray_pos.y - sdf_max_y) / abs(ray_dir.y));
        }
        ray_pos += initial_inc_len * ray_dir;

        vec3 map_pos = floor(ray_pos / cloud_voxel_size);
        vec3 orig_map_pos = map_pos;
        
        vec3 delta_dist = abs(vec3(length(ray_dir)) / ray_dir);

        vec3 ray_step = sign(ray_dir);

        vec3 side_dist = (sign(ray_dir) * (map_pos - ray_pos / cloud_voxel_size) + (sign(ray_dir) * 0.5) + 0.5) * delta_dist;

        bvec3 mask;

        float tbx = float(worldDay) + float(worldTime) / 24000.0;
        float thresh_base = 7.0 + 0.55555 * (sin(tbx+cos(2.0*tbx)) - 0.8*cos(0.2*tbx - sin(tbx)));

        float curr_alpha = 0.0;
        for (int i = 0; i < max_occlusion_steps; i++) {
            float thresh = thresh_base - rainStrength * 2.0 - thunderStrength * 4.0;
            float sdf_dist = SDF_FUNC(map_pos * cloud_voxel_size, thresh);
            float lod = pow(2.0, floor(distance(orig_map_pos.xz, map_pos.xz)/lod_distance_step));

            if (ssr_view_to_screen(world_to_view(map_pos * cloud_voxel_size), mats).z > curr_depth_opaque) {
                // break;
            } else if (sdf_dist < 0.0) {
                curr_alpha = min(curr_alpha + lod * max_occlusion / max_occlusion_dist, max_occlusion);
                if (curr_alpha == max_occlusion) {
                    break;
                }
            }

            // Boolean masking magic to skip branching
            mask = lessThanEqual(side_dist.xyz, min(side_dist.yzx, side_dist.zxy));

            side_dist += vec3(mask) * delta_dist;
            map_pos += vec3(mask) * ray_step * lod;

            if ((map_pos.y * cloud_voxel_size > sdf_max_y && ray_dir.y > 0) || (map_pos.y * cloud_voxel_size < sdf_min_y && ray_dir.y < 0)) {
                break;
            }

            // curr_point += ray_dir * max(dist_per_step, abs(sdf_dist));
        }

        // vec3 sun_grad_dot_dir = normalize(mat3(gbufferModelViewInverse) * sunPosition) * 0.1;
        // float normal_dot_sundir = SDF_FUNC(curr_point + sun_grad_dot_dir) / 0.1;

        // curr_depth = ssr_view_to_screen(curr_point, mats).z;
        // out_colortex0 = vec4(normal_dot_sundir * 0.4 + 0.6);
        // out_colortex0 = vec4(1.0);

        vec4 cloud_fog = get_fog_color(
            texcoord, world_to_view(map_pos),
            cameraPosition.y,
            DEFAULT_FOG_MATS,
            skyColor, fogColor,
            sunPosition, moonPosition,
            DEFAULT_FOG_PARAMS
        );

        // vec3 cloud_col = mix(vec3(0.8 + 0.2*avg_normal_dot_sundir), cloud_fog.rgb, cloud_fog.a);
        vec3 cloud_col = mix(vec3(0.6), cloud_fog.rgb, cloud_fog.a);
        out_colortex0.rgb = mix(out_colortex0.rgb, cloud_col, curr_alpha * (1.0 - cloud_fog.a));
        // out_colortex0.rgb = mix(out_colortex0.rgb, vec3(1.0, 0.0, 0.0), curr_alpha);
    #endif

    // out_colortex0.rgb = vec3(closest_dist * 0.05);

    vec4 rainless_colortex0 = out_colortex0;

    vec4 base_ctex3 = texture(colortex3, texcoord);
    vec3 weather_color = base_ctex3.rgb;

    #ifdef RAIN_REFRACTION
        if (base_ctex3.a > 1.1) {
            base_ctex3.a -= 1.0;

            vec3 normal = base_ctex3.rgb * 2.0 - 1.0;
            normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
            normal = normalize(normal);

            vec3 uvw = vec3(texcoord, base_ctex3.b);

            // SSRMats mats = SSRMATS_DEFAULT_CONSTRUCTOR;

            vec3 view_pos = ssr_screen_to_view(uvw, mats);
            vec3 refract_dir = refract(normalize(view_pos), normal, 1.33);

            // Scuffed because it uses current frame's normals, but should be enough for rain
            SSRResult ssr_result_refract = ssr_raytrace(view_pos, refract_dir, colortex13, colortex7, mats);

            FogMats fog_mats = DEFAULT_FOG_MATS;
            FogValues fog_values = eval_values(DEFAULT_FOG_PARAMS, fog_mats);
            vec3 col_refract;
            vec3 col_reflect;
            float refract_alpha_sub = 0.0;
            float reflect_alpha_sub = 0.0;

            switch (ssr_result_refract.error_code) {
                case 0:
                    col_refract = texture(colortex14, ssr_result_refract.hit_uv).rgb;
                    break;
                case SSR_ERR_HIT_NORMAL_MISMATCH:
                case SSR_ERR_ITERATIONS_EXCEEDED:
                    col_refract = texture(colortex14, texcoord + (texcoord-0.5)*64.0/vec2(viewWidth, viewHeight)).rgb;
                    break;
                case SSR_ERR_OUT_OF_SCREEN:
                default:
                    col_refract = sky_calc_color(normalize(ssr_result_refract.viewspace_hit_dir), fog_mats, skyColor, fogColor, sunPosition, moonPosition, eyeBrightness, fog_values);
                    refract_alpha_sub = 0.4;
                    break;
            }

            float mixval = abs(dot(normal, vec3(0.0, 0.0, 1.0)));
            weather_color = col_refract;
            base_ctex3.a -= refract_alpha_sub;

            // switch (ssr_result_refract.error_code) {
            //     case 0:
            //         weather_color = vec3(1.0);
            //         break;
            //     case SSR_ERR_HIT_NORMAL_MISMATCH:
            //         weather_color = vec3(1.0, 0.0, 0.0);
            //         break;
            //     case SSR_ERR_ITERATIONS_EXCEEDED:
            //         weather_color = vec3(0.0, 1.0, 0.0);
            //         break;
            //     case SSR_ERR_OUT_OF_SCREEN:
            //         weather_color = vec3(0.0, 0.0, 1.0);
            //         break;
            // }

            // weather_color = normal;
        }
    #else
        weather_color = mix(weather_color, vec3(76, 155, 245)/255.0, clamp(floor(base_ctex3.a)+0.1, 0.0, 1.0));
        base_ctex3.a = fract(base_ctex3.a);
    #endif

    // if (base_hsv.y > 0.3 && base_hsv.z < 0.85) {
    //     weather_color = mix(weather_color*1.1, texture(colortex14, texcoord - sign(texcoord - 0.5)*max(abs(texcoord - 0.5), 0.1) * 64 * screen_res_mult / vec2(viewWidth, viewHeight)).rgb, 0.95);
    // }

    out_colortex0.rgb = mix(out_colortex0.rgb, weather_color, base_ctex3.a);
    out_colortex14 = rainless_colortex0;
    out_colortex13 = vec4(curr_depth, texture(depthtex1, texcoord).r, 0.0, 1.0);
}