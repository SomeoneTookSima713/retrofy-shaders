#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/ssr.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/effects/volumetric_clouds.glsl"
#include "/lib/colors.glsl"
#include "/lib/weather_encoding.glsl"

uniform sampler2D colortex0;
uniform usampler2D colortex3;
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

/*
// Would be true if I actually used SSR
const bool colortex13MipmapEnabled = false;
const bool colortex7MipmapEnabled = false;
*/

void main() {
    out_colortex0 = texture(colortex0, texcoord);
    float curr_depth = texture(depthtex0, texcoord).r;
    float curr_depth_opaque = texture(depthtex1, texcoord).r;

    // out_colortex0.rgb = vec3(closest_dist * 0.05);

    vec4 rainless_colortex0 = out_colortex0;

    uint weather_info = texelFetch(colortex3, ivec2(gl_FragCoord.xy), 0).r;
    vec4 final_weather_col;

    #ifdef RAIN_REFRACTION
        if (weatherenc_is_refracting_rain(weather_info)) {
            vec3 normal_and_depth = weatherenc_decode_refracting_rain(weather_info);
            vec3 normal = vec3(normal_and_depth.xy, sqrt(1.0 - dot(normal_and_depth.xy, normal_and_depth.xy)));
            vec3 uvw = vec3(texcoord, normal_and_depth.z);

            SSRMats mats = SSRMATS_DEFAULT_CONSTRUCTOR;

            vec3 view_pos = ssr_screen_to_view(uvw, mats);
            vec3 refract_dir = refract(normalize(view_pos), normal, 1.33);

            // // Scuffed because it uses current frame's normals, but should be enough for rain
            // // SSRResult ssr_result_refract = ssr_raytrace(view_pos, refract_dir, colortex13, colortex7, mats);
            // SSRResult ssr_result_refract = ssr_raytrace(uvw * 2.0 - 1.0, view_pos, refract_dir, vec2(viewWidth, viewHeight), colortex13, colortex7, mats);

            // FogMats fog_mats = DEFAULT_FOG_MATS;
            // FogValues fog_values = eval_values(DEFAULT_FOG_PARAMS, fog_mats);
            // vec3 col_refract;

            // switch (ssr_result_refract.error_code) {
            //     case 0:
            //         col_refract = texture(colortex14, ssr_result_refract.hit_uvw.xy).rgb;
            //         break;
            //     case SSR_ERR_HIT_NORMAL_MISMATCH:
            //     case SSR_ERR_ITERATIONS_EXCEEDED:
            //         col_refract = texture(colortex14, texcoord + (texcoord-0.5)*64.0/vec2(viewWidth, viewHeight)).rgb;
            //         break;
            //     case SSR_ERR_OUT_OF_SCREEN:
            //     default:
            //         col_refract = sky_calc_color(normalize(ssr_result_refract.viewspace_hit_dir), fog_mats, skyColor, fogColor, sunPosition, moonPosition, eyeBrightness, fog_values);
            //         break;
            // }

            vec3 col_refract = texture(colortex14, texcoord + (texcoord-0.5)*64.0/vec2(viewWidth, viewHeight)).rgb;

            float mixval = abs(dot(normal, vec3(0.0, 0.0, 1.0)));
            final_weather_col = vec4(mix(col_refract, vec3(130, 155, 186)/vec3(255.0), 0.1), 0.8);
        } else {
            final_weather_col = weatherenc_decode_regular_weather(weather_info);
        }
    #else
        final_weather_col = weatherenc_decode_regular_weather(weather_info);
    #endif

    // if (base_hsv.y > 0.3 && base_hsv.z < 0.85) {
    //     weather_color = mix(weather_color*1.1, texture(colortex14, texcoord - sign(texcoord - 0.5)*max(abs(texcoord - 0.5), 0.1) * 64 * screen_res_mult / vec2(viewWidth, viewHeight)).rgb, 0.95);
    // }

    // out_colortex0.rgb = mix(out_colortex0.rgb, weather_color, base_ctex3.a);
    out_colortex0.rgb = mix(out_colortex0.rgb, final_weather_col.rgb, final_weather_col.a);

    // out_colortex0.rgb = vec3(float(weather_info & WEATHERENC_BIT_IS_SNOW), 0.0, 0.0);

    out_colortex14 = rainless_colortex0;
    out_colortex13 = vec4(curr_depth, curr_depth_opaque, 0.0, 1.0);
}