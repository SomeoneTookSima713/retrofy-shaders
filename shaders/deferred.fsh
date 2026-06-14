#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/ssao.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/colors.glsl"
#include "/lib/unified_depth.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex16; // voxy_colortex0
uniform sampler2D colortex17; // voxy_lightmap_data
uniform sampler2D colortex18; // voxy_encoded_normal
uniform sampler2D colortex19; // voxy_dh_stuff_mask
uniform sampler2D depthtex0;

#define voxy_colortex0 colortex16
#define voxy_lightmap_data colortex17
#define voxy_encoded_normal colortex18
#define voxy_dh_stuff_mask colortex19

#if defined DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
    uniform mat4 dhProjectionInverse;
    #define LOD_DEPTHTEX dhDepthTex0
    #define LOD_DEPTHTEX_FULL dhDepthTex0
    #define LOD_INV_PROJ dhProjectionInverse
#elif defined VOXY
    uniform sampler2D vxDepthTexOpaque;
    uniform sampler2D vxDepthTexTrans;
    uniform mat4 vxProjInv;
    #define LOD_DEPTHTEX vxDepthTexOpaque
    #define LOD_DEPTHTEX_FULL vxDepthTexTrans
    #define LOD_INV_PROJ vxProjInv
#else
    #define LOD_DEPTHTEX depthtex0
    #define LOD_DEPTHTEX_FULL depthtex0
    #define LOD_INV_PROJ gbufferProjectionInverse
#endif

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float eyeAltitude;
uniform ivec3 cameraPositionInt;
uniform vec3 cameraPosition;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float sunAngle;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float viewWidth;
uniform float viewHeight;

uniform float wetness;
uniform float rainStrength;
uniform float thunderStrength;

uniform bool isEyeInWater;

uniform ivec2 eyeBrightness;

uniform float fogEnd;

uniform int heldItemId;
uniform int heldItemId2;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 out_colortex0;
// layout(location = 1) out vec4 out_lightmap_data;
// layout(location = 2) out vec4 out_encoded_normal;
// layout(location = 3) out vec4 out_dh_stuff_mask;

void main() {
    out_colortex0 = texture(colortex0, texcoord);

    #if defined DISTANT_HORIZONS
        // DH SSAO
        if (texture(depthtex0, texcoord).r == 1.0 && texture(colortex8, texcoord).g > 0.5) {
            float ao = get_ssao_occlusion(texcoord, dhDepthTex0, colortex7, noisetex, SSAOMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse));
            out_colortex0.rgb *= 1.0 + ao;
        }
    #elif defined VOXY
        // Voxy SSAO
        if (texture(colortex8, texcoord).g > 0.5) {
            float ao = get_ssao_occlusion(texcoord, vxDepthTexOpaque, colortex7, noisetex, SSAOMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse));
            out_colortex0.rgb *= 1.0 + ao;
        }
    #endif

	// Fog
    #if defined DISTANT_HORIZONS
    if (texture(depthtex0, texcoord).r < 1.0 || texture(dhDepthTex0, texcoord).r < 1.0) {
    #elif defined VOXY
    if (texture(depthtex0, texcoord).r < 1.0 || texture(vxDepthTexOpaque, texcoord).r < 1.0) {
    #else
    if (texture(depthtex0, texcoord).r < 1.0) {
    #endif
        vec3 viewspace = unidepth_get_viewspace_position(texcoord, depthtex0, LOD_DEPTHTEX, gbufferProjectionInverse, LOD_INV_PROJ);
        // float fog_amount = get_fog_amount(viewspace, eyeAltitude, gbufferModelViewInverse);

        // color.rgb = mix(color.rgb, calcSkyColor(normalize(screenToView(vec3(texcoord, 1.0), gbufferProjectionInverse)), gbufferModelView, skyColor, fogColor, sunPosition, moonPosition, FOG_SUN_COLOR, FOG_MOON_COLOR), fog_amount);
        // color.rgb = vec3(get_z_unified(texcoord, depthtex0, dhDepthTex0, gbufferProjectionInverse, dhProjectionInverse)*0.005, 0.0, 0.0);
        vec4 fog_col = get_fog_color(
            texcoord, viewspace,
            eyeAltitude,
            FogMats(
                gbufferModelView, gbufferModelViewInverse,
                gbufferProjection, gbufferProjectionInverse,
                LOD_INV_PROJ
            ),
            skyColor, fogColor,
            sunPosition, moonPosition,
            eyeBrightness,
            DEFAULT_FOG_PARAMS
            // FogPlanes(near, far, dhNearPlane, dhFarPlane)
        );
        out_colortex0.rgb = mix(out_colortex0.rgb, fog_col.rgb, fog_col.a);
    }

    // if (1.0 - texture(depthtex0, texcoord).r < 0.001) {
    //     vec4 voxy_translucent = texture(voxy_colortex0, texcoord);
    //     out_colortex0.rgb = mix(out_colortex0.rgb, voxy_translucent.rgb, voxy_translucent.a);

    //     vec4 voxy_lightmap = texture(voxy_lightmap_data, texcoord);
    //     vec4 curr_lightmap = texture(colortex1, texcoord);
    //     out_lightmap_data = mix(curr_lightmap, voxy_lightmap, voxy_lightmap.a);

    //     vec4 voxy_normal = texture(voxy_encoded_normal, texcoord);
    //     vec4 curr_normal = texture(colortex7, texcoord);
    //     out_encoded_normal = mix(curr_normal, voxy_normal, voxy_normal.a);

    //     out_dh_stuff_mask = texture(voxy_dh_stuff_mask, texcoord);
    // }
}