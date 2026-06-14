#ifndef FX_FOG
#define FX_FOG

#include "/effects/options.glsl"
#include "/lib/unified_depth.glsl"

struct FogMats {
    mat4 model_view;
    mat4 model_view_inv;
    mat4 proj;
    mat4 proj_inv;
    mat4 dh_proj_inv;
};

struct FogParams {
    float world_time;
    float wetness;
    float rain_strength;
    float thunder_strength;
    float submerged;
    vec3 camera_position;
    bool is_holding_spyglass;
};

struct FogValues {
    float strength;
    float falloff;
    float max_dist;
    float tint_mult;
    float player_y;
    float spyglass_thingy;
};

#define DEFAULT_FOG_MATS FogMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse, dhProjectionInverse)
#define DEFAULT_FOG_PARAMS FogParams(sunAngle, wetness, rainStrength, thunderStrength, float(int(isEyeInWater))*(1.0+float(int(fogEnd < 2.0))), cameraPosition, heldItemId == 71 || heldItemId2 == 71)

float sky_fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 sky_calc_color(vec3 pos, FogMats mats, vec3 sky_col, vec3 fog_col, vec3 sun_dir, vec3 moon_dir, ivec2 eye_brightness, FogValues vals) {
    vec3 dir = normalize(pos);
    float worldspace_y = (mats.model_view_inv * vec4(pos, 1.0)).y + vals.player_y;

	float up_dot = dot(dir, mats.model_view[1].xyz); //not much, what's up with you?

    vec3 sun_col = mix(fog_col, FOG_SUN_COLOR, vals.tint_mult);
    vec3 moon_col = mix(fog_col, FOG_MOON_COLOR, vals.tint_mult);

	vec3 pos_view = (mats.model_view * vec4(dir, 1.0)).xyz;
	float sun_dot = dot(dir, normalize(sun_dir))-0.3+clamp(dot(normalize(sun_dir), mats.model_view[1].xyz)*2.0, -1.0, 0.0);
	float moon_dot = dot(dir, normalize(moon_dir))-0.3+clamp(dot(normalize(moon_dir), mats.model_view[1].xyz)*2.0, -1.0, 0.0);

    #ifdef OVERWORLD
	vec3 celestial_impacted_fog_col = mix(mix(fog_col, sun_col, max(sun_dot, 0.0)*sun_dot), moon_col, max(moon_dot, 0.0)*moon_dot);
    vec3 cave_fog_col = mix(vec3(0.0), celestial_impacted_fog_col, clamp(eye_brightness.y/120.0, 0.0, 1.0));

    vec3 final_fog_col = mix(celestial_impacted_fog_col, cave_fog_col, clamp((63.0 - worldspace_y) * 0.03, 0.0, 1.0));
	#else
    vec3 final_fog_col = fog_col;
    #endif

    // vec3 finalFogColor = vec3(sunDot, 0.0, 0.0);

	return mix(sky_col, final_fog_col, sky_fogify(max(up_dot, 0.0), 0.25));
}


#define FOG_APPLY_MOD(BASE, MOD, MODVAL) BASE = MOD(BASE, MODVAL)

FogValues eval_values(FogParams params, FogMats mats) {
    float spyglass_thingy = clamp((PLAYER_FOV-atan(mats.proj_inv[1].y) / 3.1415926 * 360.0)/(0.9*PLAYER_FOV), 0.0, 1.0) * float(int(params.is_holding_spyglass));
    FogValues base = FogValues(FOG_BASE_STRENGTH, FOG_FALLOFF, FOG_MAX_DIST, 1.0, params.camera_position.y, spyglass_thingy);

    FOG_APPLY_MOD(base.strength, FOG_STRENGTH_TIME_MOD, params.world_time);
    FOG_APPLY_MOD(base.strength, FOG_STRENGTH_RAIN_MOD, params.rain_strength);
    FOG_APPLY_MOD(base.strength, FOG_STRENGTH_THUNDER_MOD, params.thunder_strength);
    FOG_APPLY_MOD(base.strength, FOG_STRENGTH_WETNESS_MOD, params.wetness);
    FOG_APPLY_MOD(base.strength, FOG_STRENGTH_SUBMERGED_MOD, params.submerged);

    FOG_APPLY_MOD(base.falloff, FOG_FALLOFF_TIME_MOD, params.world_time);
    FOG_APPLY_MOD(base.falloff, FOG_FALLOFF_RAIN_MOD, params.rain_strength);
    FOG_APPLY_MOD(base.falloff, FOG_FALLOFF_THUNDER_MOD, params.thunder_strength);
    FOG_APPLY_MOD(base.falloff, FOG_FALLOFF_WETNESS_MOD, params.wetness);
    FOG_APPLY_MOD(base.falloff, FOG_FALLOFF_SUBMERGED_MOD, params.submerged);

    FOG_APPLY_MOD(base.max_dist, FOG_DIST_TIME_MOD, params.world_time);
    FOG_APPLY_MOD(base.max_dist, FOG_DIST_RAIN_MOD, params.rain_strength);
    FOG_APPLY_MOD(base.max_dist, FOG_DIST_THUNDER_MOD, params.thunder_strength);
    FOG_APPLY_MOD(base.max_dist, FOG_DIST_WETNESS_MOD, params.wetness);
    FOG_APPLY_MOD(base.max_dist, FOG_DIST_SUBMERGED_MOD, params.submerged);

    FOG_APPLY_MOD(base.tint_mult, FOG_TINT_TIME_MOD, params.world_time);
    FOG_APPLY_MOD(base.tint_mult, FOG_TINT_RAIN_MOD, params.rain_strength);
    FOG_APPLY_MOD(base.tint_mult, FOG_TINT_THUNDER_MOD, params.thunder_strength);
    FOG_APPLY_MOD(base.tint_mult, FOG_TINT_WETNESS_MOD, params.wetness);
    FOG_APPLY_MOD(base.tint_mult, FOG_TINT_SUBMERGED_MOD, params.submerged);

    return base;
}

#undef FOG_APPLY_MOD

vec3 fog_get_viewspace_position(vec2 texcoord, float depth, mat4x4 projection_mat_inverse) {
    vec3 clipSpace = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewW = projection_mat_inverse * vec4(clipSpace, 1.0);
    return viewW.xyz / viewW.w;
}

float get_fog_amount(vec3 viewspace_pos, float segment_length, float camera_y, FogMats mats, FogValues vals) {

    // float amount = 1.0 - exp(-length(viewspace_pos)*FOG_FALLOFF);
    float adjusted_cam_y = max(camera_y, 63.0) - 50.0;
    float cam_to_point_y = (mat3(mats.model_view_inv) * viewspace_pos).y;
    float point_y = cam_to_point_y + camera_y - 50.0;

    float amount = 0.0;

    #ifdef OVERWORLD
        amount += vals.strength/vals.falloff * exp(-(camera_y)*vals.falloff) * (1.0-exp(-segment_length*point_y*vals.falloff))/point_y;
    #endif

    // Linear edge fog (it is assumed another segment of length `length(viewspace_pos) - segment_length`
    // gets added onto the pixel's color somewhere else in the shader)
    amount += segment_length/vals.max_dist;

    #ifdef AETHER
        vec4 proj = mats.proj * vec4(viewspace_pos, 1.0);
        vec2 ndc_xy = proj.xy / proj.w;
        float dist_from_screen_center = pow(pow(ndc_xy.x, 4) + pow(ndc_xy.y, 4), 0.25) * 1.2;

        amount = pow(amount, 0.25);

        float fog_reduction_amount = clamp(1.0 - 0.33*segment_length/vals.max_dist, 1.0, 0.0);
        amount *= (1.0 - vals.spyglass_thingy*fog_reduction_amount*clamp(1.0-dist_from_screen_center, 0.0, 1.0));
    #endif
    
    return clamp(amount, 0.0, 1.0);
}

float get_fog_amount(vec3 viewspace_pos, float camera_y, FogMats mats, FogValues vals) {
    return get_fog_amount(viewspace_pos, length(viewspace_pos), camera_y, mats, vals);
}

vec4 get_fog_color(vec2 uv, vec3 viewspace_pos, float segment_length, float camera_y, FogMats mats, vec3 sky_col, vec3 fog_col, vec3 sun_pos, vec3 moon_pos, ivec2 eye_brightness, FogParams params) {
    FogValues vals = eval_values(params, mats);

    vec3 color = sky_calc_color(viewspace_pos, mats, sky_col, fog_col, sun_pos, moon_pos, eye_brightness, vals);
    float amount = get_fog_amount(viewspace_pos, segment_length, camera_y, mats, vals);
    return vec4(color, amount);
}

vec4 get_fog_color(vec2 uv, vec3 viewspace_pos, float camera_y, FogMats mats, vec3 sky_col, vec3 fog_col, vec3 sun_pos, vec3 moon_pos, ivec2 eye_brightness, FogParams params) {
    return get_fog_color(uv, viewspace_pos, length(viewspace_pos), camera_y, mats, sky_col, fog_col, sun_pos, moon_pos, eye_brightness, params);
}

vec4 get_fog_color(vec2 uv, sampler2D depth, sampler2D dh_depth, float camera_y, FogMats mats, vec3 sky_col, vec3 fog_col, vec3 sun_pos, vec3 moon_pos, ivec2 eye_brightness, FogParams params) {
    vec3 viewspace_pos = unidepth_get_viewspace_position(uv, depth, dh_depth, mats.proj_inv, mats.dh_proj_inv);

    return get_fog_color(uv, viewspace_pos, camera_y, mats, sky_col, fog_col, sun_pos, moon_pos, eye_brightness, params);
}

#endif