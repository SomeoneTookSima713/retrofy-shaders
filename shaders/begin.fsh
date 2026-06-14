#version 430 compatibility

layout(std430, binding = 0) buffer MAKESHIFT_DEPTH { uint ssbo_depth_buf[]; };

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

void main() {
    // ssbo_depth_buf[int(texcoord.x * viewWidth) + int(texcoord.y * viewHeight * viewWidth)] = 2048*16;
    discard;
}