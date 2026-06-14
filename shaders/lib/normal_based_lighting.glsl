#ifndef LIB_NBL
#define LIB_NBL

// Calculates and returns a brightness multiplier based on a surface normal.
// 
// Should be used for normal-based lighting of blocks, entities etc.
// 
// `skylight_frac` is the skylight at the given position, as a float in the
// range [0,1].
float get_normal_based_tint(vec3 normal, float skylight_frac, mat4x4 model_view_inverse, vec3 sun_pos, vec3 moon_pos, int world_time) {
    vec3 sun_normal = normalize(sun_pos);
    vec3 moon_normal = normalize(moon_pos);

    // float interp_det = abs(((world_time - 6000)%24000 - 12000)/12000);
    // float interp_val = pow(interp_det, mix(1.6, 0.1, interp_det));
    float interp_val = 1.0-clamp(((mat3(model_view_inverse) * sun_normal).y+0.1)*2.0, 0.0, 1.0);

    vec3 celestial_pos = normalize((mat3(model_view_inverse)*mix(sun_normal, moon_normal, interp_val)).xyz)*abs(interp_val-0.5)*2;
    vec3 mixed_normal = mix(normalize(vec3(1,2,3)), celestial_pos, skylight_frac);

    return dot(normal, mixed_normal)*0.25+0.75;
}

#endif