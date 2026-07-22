#ifndef LIB_LOD_UTILS
#define LIB_LOD_UTILS

#define LODS_ENABLED
#if defined DISTANT_HORIZONS
    #define LOD_DEPTHTEX_OPAQUE dhDepthTex1
    #define LOD_DEPTHTEX_FULL dhDepthTex0
    #define LOD_PROJ dhProjection
    #define LOD_PROJ_INV dhProjectionInverse
    #define LOD_MODEL_VIEW gbufferModelView
    #define LOD_MODEL_VIEW_INV gbufferModelViewInverse
#elif defined VOXY
    #define LOD_DEPTHTEX_OPAQUE vxDepthTexOpaque
    #define LOD_DEPTHTEX_FULL vxDepthTexTrans
    #define LOD_PROJ vxProj
    #define LOD_PROJ_INV vxProjInv
    #define LOD_MODEL_VIEW vxModelView
    #define LOD_MODEL_VIEW_INV vxModelViewInv
#else
    #undef LODS_ENABLED
#endif

bool geometry_is_behind_lods(vec2 uv, sampler2D lod_depthtex, float geometry_depth, mat4 geometry_proj, mat4 lod_proj_inv) {
    float lod_depth = texture(lod_depthtex, uv).r;
    vec4 reproj_w = geometry_proj * lod_proj_inv * vec4(uv * 2.0 - 1.0, lod_depth * 2.0 - 1.0, 1.0);
    return lod_depth < 1.0 && reproj_w.z / reproj_w.w < geometry_depth * 2.0 - 1.0;
}

#endif