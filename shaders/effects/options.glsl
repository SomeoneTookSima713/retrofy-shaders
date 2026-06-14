#ifndef FX_OPTIONS
#define FX_OPTIONS

#define PLAYER_FOV 70.0 // [30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 105.0 110.0]

/** Debugging **/
//#define DEBUG_DISPLAY_LIGHT_VOXELS
//#define DEBUG_DISPLAY_LIGHT_VOXEL_STRENGTHS
//#define DEBUG_DISPLAY_FOODFILL
//#define DEBUG_ONLY_DISPLAY_LIGHT_VOXELS
//#define DEBUG_DISPLAY_BLOCKLIGHT_COL
//#define DEBUG_DISPLAY_VOXEL_SOURCE
//#define DEBUG_DISPLAY_VOXEL_INFO
#define DEBUG_DISPLAY_TEXTURE -1 // [-1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 -2 -3 -4 -5]

/** Other misc options **/
//#define DITHER_LIGHTING
#define LIGHT_DITHERING_MODE 0 // [0 1]
#define LIGHT_POSTERIZATION_COLSPACE 0 // [0 1]
#define DITHERING_REDUCTION 0.30 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95]
//#define DISABLE_BACKFACE_CULLING
//#define FULL_SHADOW_PASS
#define LIGHT_PROPAGATION_WORKGROUP_SIZE 4 // [4 8]
#define RAIN_REFRACTION

/** Features currently in Beta **/
// #define BETA_VOLUMETRIC_CLOUDS

#ifdef DEBUG_DISPLAY_LIGHT_VOXEL_STRENGTHS
#endif
#ifdef DEBUG_DISPLAY_LIGHT_VOXELS
#endif
#ifdef DEBUG_DISPLAY_FOODFILL
#endif
#ifdef DEBUG_ONLY_DISPLAY_LIGHT_VOXELS
#endif
#ifdef DEBUG_DISPLAY_BLOCKLIGHT_COL
#endif
#ifdef DEBUG_DISPLAY_VOXEL_SOURCE
#endif
#ifdef DEBUG_DISPLAY_VOXEL_INFO
#endif
#ifdef DISABLE_BACKFACE_CULLING
#endif

/** Lighting settings **/
#if defined NETHER // Nether
    // #define SKYLIGHT_COLOR vec3(255, 132, 94) / 255.0
    // #define SKYLIGHT_COLOR_NIGHT vec3(255, 132, 94) / 255.0
    #define SKYLIGHT_COLOR_HSV_MULT vec3(1.0, 0.6, 0.95)
    #define BLOCKLIGHT_COLOR vec3(191, 164, 117) / 255.0
#elif defined THE_END // End
    #define SKYLIGHT_COLOR vec3(182, 150, 255) / 255.0
    #define SKYLIGHT_COLOR_NIGHT vec3(182, 150, 255) / 255.0
    #define BLOCKLIGHT_COLOR vec3(204, 140, 245) / 255.0
#elif defined AETHER // Aether
    #define SKYLIGHT_COLOR vec3(255, 248, 240) / 255.0
    #define SKYLIGHT_COLOR_NIGHT vec3(47, 53, 61) / 255.0
    #define BLOCKLIGHT_COLOR vec3(191, 164, 117) / 255.0
#else // Overworld
    #define SKYLIGHT_COLOR vec3(255, 255, 255) / 255.0
    #define SKYLIGHT_COLOR_NIGHT vec3(47, 53, 61) / 255.0
    #define BLOCKLIGHT_COLOR vec3(191, 164, 117) / 255.0
#endif
// The minimum intensity of light (and the color of the light added if we're under this minimum)
#if defined AETHER
    #define MINIMUM_LIGHT vec4(1.0, 1.0, 1.0, 0.25)
#else
    #define MINIMUM_LIGHT vec4(1.0, 1.0, 1.0, 0.1)
#endif

#if defined NETHER // Nether
    #define AMBIENT_LIGHT_ADD 0.4
#elif defined THE_END // End
    #define AMBIENT_LIGHT_ADD 0.65
#elif defined AETHER // Aether
    #define AMBIENT_LIGHT_ADD 0.7
#else // Overworld
    #define AMBIENT_LIGHT_ADD 0.08
#endif

#define LIGHT_PIXELATION_MULT 1.0
#define LIGHT_COLOR_AMOUNT 32.0

#define DO_COLORED_LIGHTING

#define DEFAULT_LIGHT_COLOR vec3(1.0, 1.0, 1.0)
#define CUSTOM_COLORED_LIGHTS vec3[40]( \
    vec3(242, 231, 109)/255.0,  /* ambrosium/arkenium stuff */ \
    vec3(39, 245, 193)/255.0,   /* soul stuff */ \
    vec3(255, 206, 92)/255.0,   /* regular torch-like stuff */ \
    vec3(245, 53, 39)/255.0,    /* minecraft:redstone_torch */ \
    vec3(235, 87, 70)/255.0,    /* tfmg:lithium_torch */ \
    vec3(214, 132, 227)/255.0,  /* minecraft:enchanting_table */ \
    vec3(237, 121, 55)/255.0,   /* create:blaze_burner */ \
    vec3(242, 193, 109)/255.0,  /* powergrid:light_fixture */ \
    vec3(90, 22, 219)/255.0,    /* minecraft:crying_obsidian */ \
    vec3(158, 255, 210)/255.0,  /* minecraft:glow_lichen */ \
    vec3(173, 255, 233)/255.0,  /* minecraft:sea_lantern */ \
    vec3(232, 230, 179)/255.0,  /* minecraft:ochre_froglight */ \
    vec3(232, 179, 228)/255.0,  /* minecraft:pearlescent_froglight */ \
    vec3(179, 232, 205)/255.0,  /* minecraft:verdant_froglight */ \
    vec3(227, 222, 213)/255.0,  /* minecraft:white_candle */ \
    vec3(212, 210, 207)/255.0,  /* minecraft:light_gray_candle */ \
    vec3(212, 210, 207)/255.0,  /* minecraft:gray_candle */ \
    vec3(212, 210, 207)/255.0,  /* minecraft:black_candle */ \
    vec3(181, 132, 80)/255.0,   /* minecraft:brown_candle */ \
    vec3(232, 90, 90)/255.0,    /* minecraft:red_candle */ \
    vec3(245, 136, 42)/255.0,   /* minecraft:orange_candle */ \
    vec3(245, 235, 42)/255.0,   /* minecraft:yellow_candle */ \
    vec3(184, 245, 42)/255.0,   /* minecraft:lime_candle */ \
    vec3(76, 245, 42)/255.0,    /* minecraft:green_candle */ \
    vec3(42, 245, 150)/255.0,   /* minecraft:cyan_candle */ \
    vec3(42, 238, 245)/255.0,   /* minecraft:light_blue_candle */ \
    vec3(42, 147, 245)/255.0,   /* minecraft:blue_candle */ \
    vec3(137, 42, 245)/255.0,   /* minecraft:purple_candle */ \
    vec3(245, 42, 245)/255.0,   /* minecraft:magenta_candle */ \
    vec3(242, 121, 147)/255.0,  /* minecraft:pink_candle */ \
    vec3(247, 163, 84)/255.0,   /* Jack O' Lanterns and Shroomlight */ \
    vec3(252, 204, 255)/255.0,  /* minecraft:end_rod */ \
    vec3(11, 82, 92)/255.0,     /* sculk stuff */ \
    vec3(199, 80, 250)/255.0,   /* amethys stuff */ \
    vec3(168, 226, 255)/255.0,  /* beacon and nether star */ \
    vec3(139, 217, 139)/255.0,  /* minecraft:sea_pickle */ \
    vec3(245, 107, 27)/255.0,   /* minecraft:lava */ \
    vec3(168, 124, 204)/255.0,  /* purple phantasm stuff */ \
    vec3(124, 125, 204)/255.0,  /* blue phantasm stuff */ \
    vec3(209, 252, 169)/255.0   /* create:experience_block */ \
)
#define GLOWING_ENTITY_COLORS vec3[1]( \
    vec3(41, 196, 147)/255.0    /* minecraft:glow_squid */ \
)

// Colored lighting entity bin stuff
#define CLEB_SIZE 16
#define CLEB_COUNT 16
#define CLEB_CAPACITY 128 // [16 32 64 128]

/** Voxelization settings **/
#define VOXEL_AREA_SIZE 256 // [128 192 256]
#define VOXEL_AREA_RADIUS VOXEL_AREA_SIZE / 2
#if LIGHT_PROPAGATION_WORKGROUP_SIZE == 4
    #if VOXEL_AREA_SIZE == 128
        #define VOXEL_WORKGROUP_COUNT 32
    #elif VOXEL_AREA_SIZE == 192
        #define VOXEL_WORKGROUP_COUNT 48
    #elif VOXEL_AREA_SIZE == 256
        #define VOXEL_WORKGROUP_COUNT 64
    #endif
#elif LIGHT_PROPAGATION_WORKGROUP_SIZE == 8
    #if VOXEL_AREA_SIZE == 128
        #define VOXEL_WORKGROUP_COUNT 16
    #elif VOXEL_AREA_SIZE == 192
        #define VOXEL_WORKGROUP_COUNT 24
    #elif VOXEL_AREA_SIZE == 256
        #define VOXEL_WORKGROUP_COUNT 32
    #endif
#endif

/** Enchantment glint outline settings **/
#define GLINT_OUTLINE_RADIUS 7.0
#define GLINT_RADIUS_FALLOFF 12.0
#define GLINT_OUTLINE_OPACITY 0.6
#define GLINT_GLOW_PULSE_SPEED 4.0
#define GLINT_GLOW_PULSE_STRENGTH 0.25
#define GLINT_GLOW_PULSE_SIZE 16
#define GLINT_GLOW_PULSE_HANDHELD_SIZE 8
#define GLINT_GLOW_PULSE_FUNC(VAL) cos(VAL*3.1415926*0.5)*cos(VAL*3.1415926*0.5)
#define GLINT_OVERLAY_COLOR vec4(205, 117, 255, 4)/255.0
#define GLINT_BASE_HSV_MODIFIER(VAL) VAL.z = clamp(VAL.z*0.85+0.15, 0.0, 1.0); VAL.y *= 1.25;

/** Fog settings **/
#if defined NETHER
    #define FOG_BASE_STRENGTH 0.0005
    #define FOG_FALLOFF 0.0001
    #define FOG_MAX_DIST 2048.0
#elif defined THE_END
    #define FOG_BASE_STRENGTH 0.0005
    #define FOG_FALLOFF 0.0001
    #define FOG_MAX_DIST 2048.0
#elif defined AETHER
    #define FOG_BASE_STRENGTH 0.01
    #define FOG_FALLOFF 0.001
    #define FOG_MAX_DIST 256.0
#else
    #define FOG_BASE_STRENGTH 0.0004
    #define FOG_FALLOFF 0.00004
    #define FOG_MAX_DIST 2048.0
#endif
#define FOG_SUN_COLOR vec3(235, 177, 52)/255.0
#define FOG_MOON_COLOR vec3(77, 105, 120)/255.0

/* Fog modifiers (are applied as submerged(wetness(thunder(rain(time(base)))))) */
#define FOG_STRENGTH_WETNESS_MOD(BASE, WETNESS) BASE
#define FOG_STRENGTH_RAIN_MOD(BASE, RAIN) BASE
#define FOG_STRENGTH_THUNDER_MOD(BASE, THUNDER) BASE*(1.0+THUNDER)
#define FOG_STRENGTH_TIME_MOD(BASE, TIME) BASE
#define FOG_STRENGTH_SUBMERGED_MOD(BASE, SUBMERGED) BASE

#define FOG_FALLOFF_WETNESS_MOD(BASE, WETNESS) BASE*(1.0-0.5*WETNESS)
#define FOG_FALLOFF_RAIN_MOD(BASE, RAIN) BASE
#define FOG_FALLOFF_THUNDER_MOD(BASE, THUNDER) BASE
#define FOG_FALLOFF_TIME_MOD(BASE, TIME) BASE*(1.0-0.2*min(pow(0.5*cos(4.0*3.1415926*TIME)+0.5,2.0) + floor(2*TIME)*0.5, 1.0)) // https://www.desmos.com/calculator/rrpj50566q
#define FOG_FALLOFF_SUBMERGED_MOD(BASE, SUBMERGED) BASE

#define FOG_DIST_WETNESS_MOD(BASE, WETNESS) BASE
#define FOG_DIST_RAIN_MOD(BASE, RAIN) BASE*(1.0-0.1*RAIN)
#define FOG_DIST_THUNDER_MOD(BASE, THUNDER) BASE*(1.0-0.75*THUNDER)
#define FOG_DIST_TIME_MOD(BASE, TIME) BASE
#define FOG_DIST_SUBMERGED_MOD(BASE, SUBMERGED) BASE/(1+SUBMERGED*SUBMERGED*SUBMERGED*47.0)

// For the sun and moon colors
#define FOG_TINT_WETNESS_MOD(BASE, WETNESS) BASE
#define FOG_TINT_RAIN_MOD(BASE, RAIN) BASE*(1.0-0.75*RAIN)
#define FOG_TINT_THUNDER_MOD(BASE, THUNDER) BASE
#define FOG_TINT_TIME_MOD(BASE, TIME) BASE//*(1.0-0.75*min(8192.0*pow(TIME-0.75,6), 1.0))
#define FOG_TINT_SUBMERGED_MOD(BASE, SUBMERGED) BASE*clamp(1-0.7*SUBMERGED, 0.0, 1.0)

/** Screen-space reflection settings **/
#define SSR_PIXELATION_MULT 1.0
#define DO_REFLECTIONS 0

/** Screen-space ambient occlusion settings **/
#if defined DISTANT_HORIZONS
    #define SSAO_STRENGTH 0.25
    #define SSAO_OFFSET 0
    #define SSAO_FALLOFF 0.0
    #define SSAO_RAD 0.002
    #define SSAO_SAMPLES 64
#elif defined VOXY
    #define SSAO_STRENGTH 0.5
    #define SSAO_OFFSET 0
    #define SSAO_FALLOFF 0.0
    #define SSAO_RAD 0.006
    #define SSAO_SAMPLES 64
#else
    #define SSAO_STRENGTH 0.25
    #define SSAO_OFFSET 0
    #define SSAO_FALLOFF 0.0
    #define SSAO_RAD 0.002
    #define SSAO_SAMPLES 64
#endif

/** Vertex snapping settings **/
#define PSX_VERTS_NEAR_PRECISION 128.0
#define PSX_VERTS_FAR_PRECISION 16.0
#define PSX_VERTS_PRECISION_FALLOFF_DIST 96.0

/** DH settings **/
#define DH_BLEND_DISTANCE 20.0

/** Composite effect settings **/
#define RESOLUTION_TARGET_MAIN 540 // [270 540 720 1080]
#define RESOLUTION_TARGET_MAIN_UNDERWATER RESOLUTION_TARGET_MAIN / 2
#define RESOLUTION_TARGET_HAND 270 // [270 540 720 1080]
#define RESOLUTION_TARGET_HAND_UNDERWATER RESOLUTION_TARGET_HAND / 2

#define FINAL_IMAGE_COLOR_AMOUNT 16.0

#define FINAL_IMAGE_DITHERING_REDUCTION 0.30 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95]
#define FINAL_IMAGE_STYLE 2 // [0 1 2]
#define FINAL_IMAGE_STYLE_TRUECOLOR 0
#define FINAL_IMAGE_STYLE_POSTERIZED 1
#define FINAL_IMAGE_STYLE_DITHERED 2

#define FINAL_IMAGE_UNDERWATER_COLOR_MULT vec3(0.55, 0.6, 1.1);
#define FINAL_IMAGE_UNDERLAVA_COLOR_MULT vec3(1.1, 0.6, 0.55);

#endif