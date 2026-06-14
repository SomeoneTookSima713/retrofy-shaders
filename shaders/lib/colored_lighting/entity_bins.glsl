#ifndef LIB_CLH_ENTITY_BINS
#define LIB_CLH_ENTITY_BINS

#include "/effects/options.glsl"

struct CLEntityLightEncoded {
    // XXXXXXXXYYYYYYYYZZZZZZZZAAAAAAAA
    uint encoded_xy;
    uint encoded_z_age;
    uint encoded_color;
};

struct CLEntityLightDecoded {
    vec3 position;
    int age;
    vec4 color;
};

struct CLEntityBin {
    CLEntityLightEncoded[CLEB_CAPACITY] lights;
    uint light_count;
};

const int cleb_total_bins = CLEB_COUNT * CLEB_COUNT * CLEB_COUNT;
const int cleb_rel_to_abs_offset = CLEB_COUNT / 2;

#ifdef DO_COLORED_LIGHTING
    layout(std430, binding = 0) buffer CL_ENTITY_BINS {
        CLEntityBin[cleb_total_bins] cl_entity_bins;
    };
#endif

int colored_lighting_get_entity_bin(ivec3 absolute_bin_pos) {
    absolute_bin_pos = clamp(absolute_bin_pos, 0, 2*cleb_rel_to_abs_offset);
    return absolute_bin_pos.x + absolute_bin_pos.y * CLEB_COUNT + absolute_bin_pos.z * CLEB_COUNT * CLEB_COUNT;
}

vec3 colored_lighting_get_bin_world_pos(int bin_id) {
    ivec3 bin_pos = ivec3(bin_id % CLEB_COUNT, (bin_id / CLEB_COUNT) % CLEB_COUNT, bin_id / CLEB_COUNT / CLEB_COUNT);

    return vec3((bin_pos - cleb_rel_to_abs_offset) * CLEB_SIZE);
}

CLEntityLightDecoded colored_lighting_decode_entity_light(CLEntityLightEncoded encoded) {
    vec2 decoded_xy = unpackUnorm2x16(encoded.encoded_xy);
    vec2 decoded_za = unpackUnorm2x16(encoded.encoded_z_age);
    return CLEntityLightDecoded(vec3(decoded_xy, decoded_za.x) * float(CLEB_SIZE), int(encoded.encoded_z_age >> 16u), unpackUnorm4x8(encoded.encoded_color));
}

CLEntityLightEncoded colored_lighting_encode_entity_light(CLEntityLightDecoded decoded) {
    return CLEntityLightEncoded(
        // packUnorm4x8(vec4(decoded.position / float(CLEB_SIZE), decoded.age)),
        packUnorm2x16(decoded.position.xy / float(CLEB_SIZE)),
        packUnorm2x16(vec2(decoded.position.z / float(CLEB_SIZE), 0.0)) | uint(decoded.age << 16u),
        packUnorm4x8(decoded.color)
    );
}

#ifdef DO_COLORED_LIGHTING
    void colored_lighting_add_entity_light(int bin_id, vec3 bin_relative_world_pos, vec4 light_color_and_strength, int frameCounter) {
        uint light_count = atomicAdd(cl_entity_bins[bin_id].light_count, 1);
        if (light_count >= CLEB_CAPACITY) {
            atomicExchange(cl_entity_bins[bin_id].light_count, CLEB_CAPACITY);
        } else {
            cl_entity_bins[bin_id].lights[light_count] = colored_lighting_encode_entity_light(CLEntityLightDecoded(
                bin_relative_world_pos,
                frameCounter & 0x0F,
                light_color_and_strength
            ));
        }
    }

    CLEntityLightDecoded colored_lighting_get_entity_light(int bin_id, int index) {
        CLEntityLightDecoded base = index >= cl_entity_bins[bin_id].light_count
            ? CLEntityLightDecoded(vec3(0.0), 16, vec4(0.0))
            : colored_lighting_decode_entity_light(cl_entity_bins[bin_id].lights[index]);
        base.position += colored_lighting_get_bin_world_pos(bin_id);
        return base;
    }
#endif

bool colored_lighting_light_is_empty(CLEntityLightDecoded light) {
    return light.age == 16;
}

bool colored_lighting_light_is_current(CLEntityLightDecoded light, int frameCounter) {
    return light.age == ((frameCounter - 1) & 0x0F);
}

bool colored_lighting_light_is_new(CLEntityLightDecoded light, int frameCounter) {
    return light.age == (frameCounter & 0x0F);
}

bool colored_lighting_light_is_empty(CLEntityLightEncoded light) {
    return (light.encoded_z_age >> 16u) == 16;
}

bool colored_lighting_light_is_old(CLEntityLightEncoded light, int frameCounter) {
    int age = int(light.encoded_z_age >> 16u);
    
    return age != ((frameCounter - 1) & 0x0F) && age != ((frameCounter) & 0x0F);
}

bool colored_lighting_light_is_new(CLEntityLightEncoded light, int frameCounter) {
    return int(light.encoded_z_age >> 16u) == (frameCounter & 0x0F);
}

#endif