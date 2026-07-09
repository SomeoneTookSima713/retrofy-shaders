#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/ssao.glsl"
#include "/effects/fog_and_sky.glsl"
#include "/lib/colors.glsl"
#include "/lib/unified_depth.glsl"
#include "/lib/lod_utils.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#ifdef VOXY
    uniform sampler2D colortex16; // voxy_colortex0
    uniform sampler2D colortex17; // voxy_lightmap_data
    uniform sampler2D colortex18; // voxy_encoded_normal
    uniform sampler2D colortex19; // voxy_dh_stuff_mask
    #define voxy_colortex0 colortex16
    #define voxy_lightmap_data colortex17
    #define voxy_encoded_normal colortex18
    #define voxy_dh_stuff_mask colortex19
#endif

// #if defined DISTANT_HORIZONS
//     uniform sampler2D dhDepthTex0;
//     uniform mat4 dhProjectionInverse;
//     #define LOD_DEPTHTEX dhDepthTex0
//     #define LOD_DEPTHTEX_FULL dhDepthTex0
//     #define LOD_INV_PROJ dhProjectionInverse
// #elif defined VOXY
//     uniform sampler2D vxDepthTexOpaque;
//     uniform sampler2D vxDepthTexTrans;
//     uniform mat4 vxProjInv;
//     #define LOD_DEPTHTEX vxDepthTexOpaque
//     #define LOD_DEPTHTEX_FULL vxDepthTexTrans
//     #define LOD_INV_PROJ vxProjInv
// #else
//     #define LOD_DEPTHTEX depthtex0
//     #define LOD_DEPTHTEX_FULL depthtex0
//     #define LOD_INV_PROJ gbufferProjectionInverse
// #endif

#ifdef LODS_ENABLED
uniform sampler2D LOD_DEPTHTEX_OPAQUE;
uniform sampler2D LOD_DEPTHTEX_FULL;
uniform mat4 LOD_PROJ_INV;
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

    // #if defined DISTANT_HORIZONS
    //     // DH SSAO
    //     if (texture(depthtex0, texcoord).r == 1.0 && texture(colortex8, texcoord).g > 0.5) {
    //         float ao = get_ssao_occlusion(texcoord, dhDepthTex0, colortex7, noisetex, vec2(viewWidth, viewHeight), SSAOMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse));
    //         // out_colortex0.rgb *= 1.0 + ao;
    //         out_colortex0.rgb *= ao;
    //     }
    // #elif defined VOXY
    //     // Voxy SSAO
    //     if (texture(colortex8, texcoord).g > 0.5) {
    //         float ao = get_ssao_occlusion(texcoord, vxDepthTexOpaque, colortex7, noisetex, vec2(viewWidth, viewHeight), SSAOMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse));
    //         // out_colortex0.rgb *= 1.0 + ao;
    //         out_colortex0.rgb *= ao;
    //         // out_colortex0.rgb = vec3(1.0 + ao * 0.5);
    //         // out_colortex0.rgb = vec3(ao);
    //     }
    // #endif

    // LOD SSAO (independant of LOD mod :D)
    #ifdef LODS_ENABLED
        vec3 reproj_uvw = unidepth_reproject_uvw_to_vanilla(vec3(texcoord, texture(LOD_DEPTHTEX_FULL, texcoord).r), LOD_PROJ_INV, gbufferProjection);
        if (texture(colortex8, texcoord).g > 0.5 && reproj_uvw.z < texture(depthtex0, texcoord).r) {
            float ao = get_ssao_occlusion(texcoord, LOD_DEPTHTEX_FULL, colortex7, noisetex, vec2(viewWidth, viewHeight), SSAOMats(gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse));
            out_colortex0.rgb *= ao;
        }
    #endif

	// Fog
    #if defined DISTANT_HORIZONS
        if (texture(depthtex0, texcoord).r < 1.0 || texture(dhDepthTex0, texcoord).r < 1.0) {
            vec3 viewspace = unidepth_get_viewspace_position(texcoord, depthtex0, LOD_DEPTHTEX_FULL, gbufferProjectionInverse, LOD_PROJ_INV);

            vec4 fog_col = get_fog_color(
                texcoord, viewspace,
                eyeAltitude,
                FogMats(
                    gbufferModelView, gbufferModelViewInverse,
                    gbufferProjection, gbufferProjectionInverse,
                    LOD_PROJ_INV
                ),
                skyColor, fogColor,
                sunPosition, moonPosition,
                eyeBrightness,
                DEFAULT_FOG_PARAMS
                // FogPlanes(near, far, dhNearPlane, dhFarPlane)
            );
            out_colortex0.rgb = mix(out_colortex0.rgb, fog_col.rgb, fog_col.a);
        }
    #elif defined VOXY
        if (texture(vxDepthTexTrans, texcoord).r < 1.0) {
            vec4 view_w = LOD_PROJ_INV * vec4(vec3(texcoord, texture(vxDepthTexOpaque, texcoord).r) * 2.0 - 1.0, 1.0);
            vec3 viewspace_opaque = view_w.xyz / view_w.w;

            view_w = LOD_PROJ_INV * vec4(vec3(texcoord, texture(vxDepthTexTrans, texcoord).r) * 2.0 - 1.0, 1.0);
            vec3 viewspace_full = view_w.xyz / view_w.w;

            float dist = distance(viewspace_opaque, viewspace_full);
            dist = dist < 0.001 ? length(viewspace_opaque) : dist;
            vec4 fog_col = get_fog_color(
                texcoord, viewspace_opaque, dist,
                eyeAltitude,
                FogMats(
                    gbufferModelView, gbufferModelViewInverse,
                    gbufferProjection, gbufferProjectionInverse,
                    #ifdef LODS_ENABLED
                        LOD_PROJ_INV
                    #else
                        gbufferProjectionInverse
                    #endif
                ),
                skyColor, fogColor,
                sunPosition, moonPosition,
                eyeBrightness,
                DEFAULT_FOG_PARAMS
                // FogPlanes(near, far, dhNearPlane, dhFarPlane)
            );
            out_colortex0.rgb = mix(out_colortex0.rgb, fog_col.rgb, fog_col.a);

            // Composite the translucent stuff over the opaque stuff
            vec4 translucent_color = texture(voxy_colortex0, texcoord);
            #ifdef RENDER_LMCOORD
                vec4 translucent_lightmap = texture(voxy_lightmap_data, texcoord);
            #endif
            vec4 translucent_normal = texture(voxy_encoded_normal, texcoord);
            vec4 translucent_dh_stuff = texture(voxy_dh_stuff_mask, texcoord);

            if (translucent_color.a > 0.001) {
                vec4 translucent_fog_col = get_fog_color(
                    texcoord, viewspace_full,
                    eyeAltitude,
                    FogMats(
                        gbufferModelView, gbufferModelViewInverse,
                        gbufferProjection, gbufferProjectionInverse,
                        #ifdef LODS_ENABLED
                            LOD_PROJ_INV
                        #else
                            gbufferProjectionInverse
                        #endif
                    ),
                    skyColor, fogColor,
                    sunPosition, moonPosition,
                    eyeBrightness,
                    DEFAULT_FOG_PARAMS
                    // FogPlanes(near, far, dhNearPlane, dhFarPlane)
                );

                out_colortex0.rgb = mix(out_colortex0.rgb, translucent_color.rgb, translucent_color.a);
                out_colortex0.rgb = mix(out_colortex0.rgb, translucent_fog_col.rgb, translucent_fog_col.a);
            }

            // out_colortex0.rgb = vec3(length(viewspace_full) * 0.001, 0.0, 0.0);
            // TODO apply everything else
        } else if (texture(depthtex0, texcoord).r < 1.0) {
            vec4 view_w = gbufferProjectionInverse * vec4(vec3(texcoord, texture(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);

            vec3 viewspace = view_w.xyz / view_w.w;

            vec4 fog_col = get_fog_color(
                texcoord, viewspace,
                eyeAltitude,
                FogMats(
                    gbufferModelView, gbufferModelViewInverse,
                    gbufferProjection, gbufferProjectionInverse,
                    LOD_PROJ_INV
                ),
                skyColor, fogColor,
                sunPosition, moonPosition,
                eyeBrightness,
                DEFAULT_FOG_PARAMS
                // FogPlanes(near, far, dhNearPlane, dhFarPlane)
            );
            out_colortex0.rgb = mix(out_colortex0.rgb, fog_col.rgb, fog_col.a);
        }
    #else
        if (texture(depthtex0, texcoord).r < 1.0) {
            vec4 view_w = gbufferProjectionInverse * vec4(vec3(texcoord, texture(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);

            vec3 viewspace = view_w.xyz / view_w.w;

            vec4 fog_col = get_fog_color(
                texcoord, viewspace,
                eyeAltitude,
                FogMats(
                    gbufferModelView, gbufferModelViewInverse,
                    gbufferProjection, gbufferProjectionInverse,
                    gbufferProjectionInverse
                ),
                skyColor, fogColor,
                sunPosition, moonPosition,
                eyeBrightness,
                DEFAULT_FOG_PARAMS
                // FogPlanes(near, far, dhNearPlane, dhFarPlane)
            );
            out_colortex0.rgb = mix(out_colortex0.rgb, fog_col.rgb, fog_col.a);
        }
    #endif

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