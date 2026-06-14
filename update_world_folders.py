import os
from os import path
import shutil

# WORLD_FOLDERS = {
#     "world0": "OVERWORLD",
#     "world-1": "NETHER",
#     "world1": "THE_END"
# }
WORLD_FOLDERS = {
    "dim_overworld": "OVERWORLD",
    "dim_nether": "NETHER",
    "dim_the_end": "THE_END",
    "dim_aether": "AETHER",
}

VOXY_STUFF = [
    "voxy_opaque.glsl",
    "voxy_translucent.glsl",
    "voxy.json"
]

for world in WORLD_FOLDERS:
    for f in os.listdir(path.join("shaders", world)):
        os.remove(path.join("shaders", world, f))

# Update discovered world folders
for f in os.listdir("shaders"):
    p = path.join("shaders", f)
    if (f.endswith(".vsh") or f.endswith(".fsh") or f.endswith(".csh") or f.endswith(".gsh") or f in VOXY_STUFF) and path.isfile(p):
        for folder in WORLD_FOLDERS:
            with open(path.join("shaders", folder, f), "w") as file:
                file.write(f"#define {WORLD_FOLDERS[folder]}\n#include \"/{f}\"")