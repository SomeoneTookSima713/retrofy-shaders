#ifndef FX_VOL_CLOUDS
#define FX_VOL_CLOUDS

#include "/lib/sdf.glsl"
#include "/lib/fbm_noise.glsl"

const int vol_cloud_base_horiz_extents = 256;
const float vcbhe_float = float(vol_cloud_base_horiz_extents);
const int vol_cloud_base_vert_extents = 48;
const float vcbve_float = float(vol_cloud_base_vert_extents);

// #define SDF_FUNC_BASE(point) (vol_cloud_sdf_func(point) + 4.0*fbm(point))
#define SDF_FUNC_BASE(point, thresh) (thresh*2.0-fbm(point*vec3(0.04, 0.1, 0.04))*32.0 + abs((point).y-128.0))
// #define SDF_FUNC_BASE(point) (vol_cloud_sdf_func(point))
// #define SDF_FUNC(point) SDF_FUNC_BASE(sdf_op_sym_xz(point + vec3(16.0, 0.0, 16.0)) - vec3(16.0, 0.0, 16.0))
#define SDF_FUNC(point, thresh) SDF_FUNC_BASE((point + vec3(0.5)), thresh)

#endif