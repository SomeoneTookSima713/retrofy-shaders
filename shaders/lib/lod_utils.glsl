#ifndef LIB_LOD_UTILS
#define LIB_LOD_UTILS

#define LODS_ENABLED
#if defined DISTANT_HORIZONS
    #define LOD_DEPTHTEX_OPAQUE dhDepthTex1
    #define LOD_DEPTHTEX_FULL dhDepthTex0
    #define LOD_PROJ dhProjection
    #define LOD_PROJ_INV dhProjectionInverse
#elif defined VOXY
    #define LOD_DEPTHTEX_OPAQUE vxDepthTexOpaque
    #define LOD_DEPTHTEX_FULL vxDepthTexTrans
    #define LOD_PROJ vxProj
    #define LOD_PROJ_INV vxProjInv
#else
    #undef LODS_ENABLED
#endif

#endif