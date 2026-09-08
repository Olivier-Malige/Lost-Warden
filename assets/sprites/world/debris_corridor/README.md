# Debris Corridor Preparation Tiles

No TileSet resource, collisions, scene integration or procedural generator is included.

## Faded Vertical Blocks

`vertical_debris_faded_atlas.png` is a transparent 384×128 atlas: three 128×128 cells, left to right: top, repeatable middle, bottom. Stack without spacing. The outer sides have an irregular silhouette and a 12-pixel alpha falloff; the exposed top/bottom have an 18-pixel falloff. Internal joins retain opacity and were compared pixel-for-pixel, including alpha, for top→middle, middle→middle, middle→bottom and top→bottom.

Native source: `assets/sources/world/debris_corridor/vertical_debris_faded.aseprite`, three static frames tagged `top`, `middle`, `bottom`. These are placement alternatives, not animation frames. Editable assembled example: `vertical_debris_example.aseprite` in the same folder. PNG preview: `assets/art/sprite_references/style_revision/vertical_debris_example.png`.

The native source uses the generated material's RGB colors and intentional partial alpha, not the exact indexed Lost Warden 24 palette. Repeated middle segments visibly repeat the material; additional material variants can reduce repetition later. Use nearest-neighbor filtering and normal alpha blending.

## Corner-Based Corridor Tiles

`debris_corridor_atlas.png`: 256×256 transparent atlas, 4×4 cells of 64×64 pixels. Frame/index is the occupancy mask, row-major: NW=1, NE=2, SE=4, SW=8. Set a bit for solid debris at that corner. Mask 0 is empty, mask 15 is filled. Adjacent cells must agree on their shared corner states. All 128 compatible edge pairs passed pixel equality checks. Masks 5 and 10 use the authored diagonal saddle interpretation; these 16 tiles are not a 47-tile Godot terrain atlas.

Source: `assets/sources/world/debris_corridor/debris_corridor.aseprite`, 16 static frames tagged by mask; separate material and edge layers. `corridor_example.aseprite` provides an assembled corridor reference. This atlas uses hard edges and a reduced project palette; use the separate vertical atlas for the maintainer's requested faded column edges.

## Provenance

Material generated with built-in image_gen, using the accepted wreckage sheet. Exact prompt: `assets/art/sprite_references/style_revision/corridor_generation.json`. Original material: `corridor_material.png` in that directory. Native assembly controls cell dimensions, true alpha and matching edge pixels; it does not rely on the generator's seamless-texture claim. Sources can be edited in Aseprite.
