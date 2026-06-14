#ifndef BLUR_VROOM
#define BLUR_VROOM

vec4 vroom_masked_box_blur_x(sampler2D tex, sampler2D mask, vec2 uv, const int pixel_radius, float tex_size) {
    vec4 sum = vec4(0.0);
    float weight_total = 0.0;

    const int mask_comp = 0;
    const ivec2 offsets[4] = ivec2[](
        ivec2(0, 0),
        ivec2(1, 0),
        ivec2(2, 0),
        ivec2(3, 0)
    );

    tex_size = 1.0/tex_size;

    uv.x -= (float(pixel_radius))*tex_size;

    // vec4 maskval, tex0, tex1, tex2, tex3;
    vec4 maskval;
    for (int i = 0; i < pixel_radius>>1; i++) {
        maskval = textureGatherOffsets(mask, uv + vec2(tex_size * float(i<<2), 0.0), offsets, mask_comp);
        // tex0 = texture2D(tex, uv + vec2(tex_size * float(i<<2), 0.0)) * maskval[0];
        // tex1 = texture2D(tex, uv + vec2(tex_size * float(i<<2+1), 0.0)) * maskval[1];
        // tex2 = texture2D(tex, uv + vec2(tex_size * float(i<<2+2), 0.0)) * maskval[2];
        // tex3 = texture2D(tex, uv + vec2(tex_size * float(i<<2+3), 0.0)) * maskval[3];
        // sum += tex0 * tex0.a;
        // sum += tex1 * tex1.a;
        // sum += tex2 * tex2.a;
        // sum += tex3 * tex3.a;
        // weight_total += tex0.a + tex1.a + tex2.a + tex3.a;
        sum += texture2D(tex, uv + vec2(tex_size * float(i<<2), 0.0)) * maskval[0];
        sum += texture2D(tex, uv + vec2(tex_size * float(i<<2+1), 0.0)) * maskval[1];
        sum += texture2D(tex, uv + vec2(tex_size * float(i<<2+2), 0.0)) * maskval[2];
        sum += texture2D(tex, uv + vec2(tex_size * float(i<<2+3), 0.0)) * maskval[3];
        weight_total += maskval[0] + maskval[1] + maskval[2] + maskval[3];
    }

    return sum / weight_total;
}

vec4 vroom_masked_box_blur_y(sampler2D tex, sampler2D mask, vec2 uv, const int pixel_radius, float tex_size) {
    vec4 sum = vec4(0.0);
    float weight_total = 0.0;

    const int mask_comp = 0;
    const ivec2 offsets[4] = ivec2[](
        ivec2(0, 0),
        ivec2(0, 1),
        ivec2(0, 2),
        ivec2(0, 3)
    );
    
    tex_size = 1.0/tex_size;

    uv.y -= (float(pixel_radius))*tex_size;

    for (int i = 0; i < pixel_radius>>1; i++) {
        vec4 maskval = textureGatherOffsets(mask, uv + vec2(0.0, tex_size * float(i<<2)), offsets, mask_comp);
        sum += texture2D(tex, uv + vec2(0.0, tex_size * float(i<<2))) * maskval[0];
        sum += texture2D(tex, uv + vec2(0.0, tex_size * float(i<<2+1))) * maskval[1];
        sum += texture2D(tex, uv + vec2(0.0, tex_size * float(i<<2+2))) * maskval[2];
        sum += texture2D(tex, uv + vec2(0.0, tex_size * float(i<<2+3))) * maskval[3];
        weight_total += maskval[0] + maskval[1] + maskval[2] + maskval[3];
    }

    return sum / weight_total;
}

vec2 vroom_box_blur_x_rg(sampler2D tex, vec2 uv, const int pixel_radius, float tex_size) {
    vec2 sum = vec2(0.0);

    const ivec2 offsets[4] = ivec2[](
        ivec2(0, 0),
        ivec2(1, 0),
        ivec2(2, 0),
        ivec2(3, 0)
    );
    
    float uv_inc_per_sample = 1.0/tex_size;

    uv.x -= (float(pixel_radius))*uv_inc_per_sample;

    for (int i = 0; i < pixel_radius>>1; i++) {
        vec4 tex_r = textureGatherOffsets(tex, uv + vec2(uv_inc_per_sample * float(i<<2), 0.0), offsets, 0);
        vec4 tex_g = textureGatherOffsets(tex, uv + vec2(uv_inc_per_sample * float(i<<2), 0.0), offsets, 1);
        sum += vec2(
            tex_r[0] + tex_r[1] + tex_r[2] + tex_r[3],
            tex_g[0] + tex_g[1] + tex_g[2] + tex_g[3]
        );
    }

    return sum / float(pixel_radius * 2);
}

vec2 vroom_box_blur_y_rg(sampler2D tex, vec2 uv, const int pixel_radius, float tex_size) {
    vec2 sum = vec2(0.0);

    const ivec2 offsets[4] = ivec2[](
        ivec2(0, 0),
        ivec2(0, 1),
        ivec2(0, 2),
        ivec2(0, 3)
    );
    
    float uv_inc_per_sample = 1.0/tex_size;

    uv.y -= (float(pixel_radius))*uv_inc_per_sample;

    for (int i = 0; i < pixel_radius>>1; i++) {
        vec4 tex_r = textureGatherOffsets(tex, uv + vec2(0.0, uv_inc_per_sample * float(i<<2)), offsets, 0);
        vec4 tex_g = textureGatherOffsets(tex, uv + vec2(0.0, uv_inc_per_sample * float(i<<2)), offsets, 1);
        sum += vec2(
            tex_r[0] + tex_r[1] + tex_r[2] + tex_r[3],
            tex_g[0] + tex_g[1] + tex_g[2] + tex_g[3]
        );
    }

    return sum / float(pixel_radius * 2);
}

#endif