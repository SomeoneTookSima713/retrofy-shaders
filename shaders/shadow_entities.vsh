#version 430 compatibility

#include "/effects/options.glsl"
#include "/lib/colors.glsl"
#include "/lib/voxelization_encoding.glsl"
#define VOXELIZE_ENTITIES
#include "/effects/colored_lighting/voxelization.glsl"

// layout (r32ui) uniform uimage3D voxel_img;

uniform sampler2D gtexture;

uniform vec3 cameraPosition;
uniform vec3 cameraPositionFract;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;
uniform mat4 modelViewMatrix;

uniform int renderStage;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform int currentRenderedItemId;

uniform int entityId;

uniform int frameCounter;

uniform ivec2 atlasSize;

uniform bool shadow_floodfill_player;

const vec3 glowing_entity_colors[] = GLOWING_ENTITY_COLORS;
const vec3 colored_light_colors[] = CUSTOM_COLORED_LIGHTS;

in vec2 mc_midTexCoord;

void main() {
    // Who needs matrix calculations when you don't use the result anyway?
    gl_Position = vec4(2.0);

    vec3 world_vert_pos = (shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
    colored_lighting_voxelize_entities(
        world_vert_pos,
        (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy,
        mc_midTexCoord,
        currentRenderedItemId,
        gtexture,
        atlasSize,
        frameCounter
    );
}