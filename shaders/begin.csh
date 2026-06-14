#version 430 compatibility

// Clears out the old elements of entity colored light bins

#include "/effects/options.glsl"
#include "/lib/colored_lighting/entity_bins.glsl"

const ivec3 workGroups = ivec3(CLEB_COUNT, CLEB_COUNT, CLEB_COUNT);

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Used for minimising round-trips to global memory.
shared CLEntityBin work_group_bin;

uniform int frameCounter;

void swap_remove(int index) {
    if (index >= work_group_bin.light_count) { return; }
    work_group_bin.lights[index] = work_group_bin.lights[work_group_bin.light_count - 1];
    work_group_bin.light_count -= 1;
}

void main() {
    int bin_id = colored_lighting_get_entity_bin(ivec3(gl_WorkGroupID));
    // Cache the bin in work-group-local memory
    if (gl_LocalInvocationID.x == 0) {
        work_group_bin = cl_entity_bins[bin_id];
    }

    barrier();
    if (work_group_bin.light_count == 0) {
        return;
    }

    for (int i = 0; i < work_group_bin.light_count; i++) {
        if (!colored_lighting_light_is_new(work_group_bin.lights[i], frameCounter - 1)) {
            swap_remove(i);
        }
    }

    // Write the modified cached data back to global memory
    if (gl_LocalInvocationID.x == 0) {
        cl_entity_bins[bin_id] = work_group_bin;
    }
}