## Technical infos for developing the shader
### Textures
Render Texture |  Format  | Usage
---------------|----------|------------
`colortex0`    |`RGBA8`   | Main image
`colortex1`    |`RGBA8`   | Lightmap data
`colortex2`    |`RGBA8`   | ---
`colortex3`    |`R32UI`   | Weather (If R & 0x80000000 { R & 0xffffff = Snow color; R & 0x7f000000 = Snow Alpha } Else { R & 0xfff = Normal XY (6bit); R & 0x7ffff = Depth })
`colortex4`    |`RGBA8`   | Hands and selected items
`colortex5`    |`R8UI`    | Enchantment glint mask (Is glint?; Is gbuffers_hand?)
`colortex6`    |`RGBA8`   | Enchantment glint color
`colortex7`    |`RGBA8`   | Normals
`colortex8`    |`RGBA32F` | LOD Stuff Mask
`colortex9`    |`R32F`    | Enchantment glint depth (linearized depth)
`colortex10`   |`R32F`    | ---
`colortex11`   |`RGBA8`   | ---
`colortex12`   |`RGBA8`   | ---
`colortex13`   |`RG32F`   | Weatherless Last depthtex0 + depthtex1
`colortex14`   |`RGBA8`   | Weatherless Last colortex0
`colortex15`   |`R32F`    | ---

### Programs

Composite Program | Usage
------------------|------------
`deffered`        |LOD SSAO, fog (opaque stuff)
`composite1`      |Enchantment glint mask & color blur (x direction)
`composite2`      |Enchantment glint mask & color blur (y direction)
`composite3`      |Enchantment glint outline calculation
`composite4`      |Clouds, Weather effects
`final`           |Rendering the hand, misc compositing steps (pixelation, posterization)

### Block IDs
  ID range | Usage
-----------|------------
`100-199`  |Custom colored light colors
`200`      |Colored translucents that tint light
`201`      |Blocks fully ignored by colored lighting
`202`      |Blocks treated as transparent by colored lighting, not tinting any light
`1000-1063`|Overrides to the passability mask for voxelized blocks

## Changelog
### Release 1.0 (WIP)
* did some minor code cleanup
* reworked rain refraction (no SSR anymore, but optimized and compacted data format + faster, more approximated refraction)
* colored lighting is now actually turned off by default

### Beta 9
* improved passability checking
    * now light is able to only pass through blocks from certain directions
    * automatic passability detection based on block meshes is now more dynamic
    * this change may have reintroduced some flickering, but it should at most be a rare occurence
* disabled colored lighting for now
    * too buggy, *massively* inflates compile times on NVidia, and takes up more RAM on Linux than AI data centers
* redid enchantment effects
    * screen-space pixelation effect, optimized using mipmaps
* changed SSAO algorithm for LOD terrain to SAO
* improved translucency handling for Voxy LODs
* fixed some bugs/warnings
* removed some includes, minimally reduced compile times

### Beta 8
* removed dithering from Sable physics objects
* replaced all mix(a, b, step(...))'s with ... ? b : a
    * produces less GPU instructions -> slightly faster
* added option for using the shadow pass for the whole colored lighting area
    * big performance cost (roughly halves my FPS), but:
    * no light leaking (hopefully)
    * no disappearing/reappearing lights
* made automatic non-full block detection in the voxelization algorithm somewhat more robust
* fully fixed flickering of colored lighting
    * current issue: too many blocks are fully passable for light
* fixed the entity flame effect
* reworked entity colored lighting (only works on items rn)
* fixed block lighting on Sable contraptions (sky lighting is still broken, so no perceived lighting during the day)

### Beta 7
* refactored colored lighting, splitting it into two files and removing the weird and clunky snipped include system
    * uses functions instead of macro-based code snippets now
    * is faster (at least on AMD), as it now samples the 3D textures for colored lighting way less often
    * BUG: Rendering of single-block sable physics objects is bugged, as it is semi-compatible with the current colored lighting
* replaced all integer-modulo operations over power-of-two modulus' with bitwise operations
    * is faster, because for some reason integer modulo gets emulated using floats on most platforms

### Beta 6
* gated rendering lightmap info to a texture behind the `RENDER_LMCOORD` preprocessor macro
    * the flag currently goes unused, removing one texture binding and write operation from most shaders
* 6.1: Added a micro-optimization to possibly reduce the amount of used registers in `blur_but_go_vroom.glsl`'s functions

### Beta 5
* changed the NVidia translucents fix to be more robust and permanent

### Beta 4
* implemented a botch fix for translucent rendering on NVidia
* 4.1: Fixed a compiler crash 'cause I forgot to remove the usage of a commented-out boolean value

### Older versions
* idk anymore