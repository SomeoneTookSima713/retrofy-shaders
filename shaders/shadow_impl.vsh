#version 430 compatibility

#include "/effects/options.glsl"
#include "/effects/colored_lighting/voxelization.glsl"
#include "/lib/voxelization_encoding.glsl"

// layout (r32ui) uniform uimage3D voxel_img;

uniform sampler2D gtexture;
uniform vec3 cameraPositionFract;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform ivec2 atlasSize;
uniform int frameCounter;

in vec4 at_midBlock;
in vec2 mc_Entity;
in vec2 mc_midTexCoord;

void main() {
    // Who needs matrix calculations when you don't use the result anyway?
    gl_Position = vec4(2.0);

    vec3 foot_pos = (shadowModelViewInverse * vec4((gl_ModelViewMatrix * gl_Vertex).xyz, 1.0)).xyz;

    colored_lighting_voxelize_terrain(
        foot_pos + at_midBlock.xyz / 64.0 + cameraPositionFract,
        mc_Entity,
        at_midBlock,
        mc_midTexCoord,
        (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy,
        normalize(gl_Normal),
        gl_ModelViewMatrix != shadowModelView,
        false,
        gtexture,
        atlasSize,
        frameCounter
    );

    // #ifdef DO_COLORED_LIGHTING
    //     vec3 foot_pos = (shadowModelViewInverse * vec4((gl_ModelViewMatrix * gl_Vertex).xyz, 1.0)).xyz;
    //     // vec3 foot_pos = gl_Vertex.xyz; // This works as long as shadowDistanceRenderMul==1.0 && shadowDistance == voxelDistance
    //     if ((gl_VertexID & 3) == 0) {
    //         vec3 block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 + cameraPositionFract;

    //         ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_AREA_RADIUS);

    //         if (clamp(voxel_pos, ivec3(0), ivec3(VOXEL_AREA_SIZE)) == voxel_pos && distance(gl_Vertex.xyz, foot_pos)<0.01) {
    //             vec3 light_color;
    //             float block_alpha;
    //             if (mc_Entity.x >= 100.0 && mc_Entity.x < 200.0) {
    //                 light_color = CUSTOM_COLORED_LIGHTS[int(mc_Entity.x - 100.0)];
    //                 block_alpha = 1.0;
    //                 // light_color = vec3(mod(mc_Entity.x - 1000.0, 2.0)*0.5, mod(floor((mc_Entity.x - 1000.0)*0.5), 2.0)*0.5, mod(floor((mc_Entity.x - 1000.0)*0.25), 2.0)*0.5);
    //             } else {
    //                 vec4 tex = textureLod(gtexture, (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy, log2(float(atlasSize.x)));
    //                 light_color = tex.rgb * gl_Color.rgb;
    //                 block_alpha = tex.a;
    //             }

    //             if (at_midBlock.w > 0.0 && mc_Entity.x != 201.0) {
    //                 // imageStore(voxel_img, voxel_pos, uvec4(encode_color_and_light_voxel(vec4(light_color, at_midBlock.w / 15.0), frameCounter), 0, 0, 0));
    //                 uvec4 payload = uvec4(
	// 					encode_color_and_light_voxel(vec4(light_color, at_midBlock.w / 15.0)),
	// 					encode_voxel_info(VoxelInfo(true, true, false, false, frameCounter)),
	// 					0,
	// 					0
	// 				);
	// 				imageStore(voxel_img, voxel_pos, payload);
	// 			} else if (mc_Entity.x == 200.0) { // Transparent blocks that tint light (doesn't include regular glass though)
    //                 uvec4 payload = uvec4(
	// 					encode_color_and_light_voxel(vec4(light_color, 1.0)),
	// 					encode_voxel_info(VoxelInfo(false, true, true, false, frameCounter)),
	// 					0,
	// 					0
	// 				);
	// 				imageStore(voxel_img, voxel_pos, payload);
    //             } else { // TODO: Glass (should be passable and tint light, currently behaves like opaque blocks)
    //                 bool passable = block_alpha < 0.75 || mc_Entity.x == 202.0;

	// 				uvec4 payload = uvec4(
	// 					0,
	// 					encode_voxel_info(VoxelInfo(false, passable, false, false, frameCounter)),
	// 					0,
	// 					0
	// 				);
	// 				imageStore(voxel_img, voxel_pos, payload);
	// 			}
    //         }
    //     }
    // #endif
}