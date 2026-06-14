### Textures
Render Texture | Usage
---------------|------------
`colortex0`    | Main image
`colortex1`    | Lightmap data
`colortex2`    | ---
`colortex3`    | Weather
`colortex4`    | Hands and selected items
`colortex5`    | Enchantment glint mask (R=Is glint?; G=Is gbuffers_hand?; B=linearized depth)
`colortex6`    | Enchantment glint color
`colortex7`    | Normals
`colortex8`    | DH Stuff Mask
`colortex9`    | Enchantment unglint mask
`colortex10`   | ---
`colortex11`   | ---
`colortex12`   | ---
`colortex13`   | Weatherless Last depthtex0 + depthtex1
`colortex14`   | Weatherless Last colortex0
`colortex15`   | Voxy linear Z depth

### Programs

Composite Program | Usage
------------------|------------
`deffered`        |DH SSAO, fog (opaque stuff)
`composite1`      |Enchantment glint mask & color blur (x direction)
`composite2`      |Enchantment glint mask & color blur (y direction)
`composite3`      |Enchantment glint outline calculation
`composite4`      |Clouds, Weather effects
`final`           |Rendering the hand, misc compositing steps (pixelation, posterization)

### Block IDs
  ID range | Usage
-----------|------------
`1024-2047`|Glowing blocks

### Changelog
#### Beta 8
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

#### Beta 7
* refactored colored lighting, splitting it into two files and removing the weird and clunky snipped include system
    * uses functions instead of macro-based code snippets now
    * is faster (at least on AMD), as it now samples the 3D textures for colored lighting way less often
    * BUG: Rendering of single-block sable physics objects is bugged, as it is semi-compatible with the current colored lighting
* replaced all integer-modulo operations over power-of-two modulus' with bitwise operations
    * is faster, because for some reason integer modulo gets emulated using floats on most platforms

#### Beta 6
* gated rendering lightmap info to a texture behind the `RENDER_LMCOORD` preprocessor macro
    * the flag currently goes unused, removing one texture binding and write operation from most shaders
* 6.1: Added a micro-optimization to possibly reduce the amount of used registers in `blur_but_go_vroom.glsl`'s functions

#### Beta 5
* changed the NVidia translucents fix to be more robust and permanent

#### Beta 4
* implemented a botch fix for translucent rendering on NVidia
* 4.1: Fixed a compiler crash 'cause I forgot to remove the usage of a commented-out boolean value

#### Older versions
* idk anymore