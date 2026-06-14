#ifndef LIB_DH_INTERP
#define LIB_DH_INTERP

#ifdef DISTANT_HORIZONS
    #include "/effects/options.glsl"
    #include "/lib/dither.glsl"

    bool should_discard_with_blur(float signed_far_plane_dist, vec2 frag_xy) {
        return dither8x8(frag_xy, signed_far_plane_dist / DH_BLEND_DISTANCE) < 0.5;
    }
#else
    bool should_discard_with_blur(float signed_far_plane_dist, vec2 frag_xy) {
        return false;
    }
#endif

#endif