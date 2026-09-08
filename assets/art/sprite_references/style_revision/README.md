# Style Revision — 2026-09-08

Generated with the built-in image_gen tool using the maintainer's itch.io screenshot as the visual reference. Full prompts are recorded in `generation.json`.

- `industrial_wreckage_v2.png`: twelve dense industrial wreckage designs; layered bulkheads, exposed conduits, fractured silhouettes and recessed machinery.
- `enemy_silhouettes_v2.png`: bomber, sniper and swept-wing hunter, left to right. Ships face up. Dark armor and sparse red accents follow the banner warship.

These are new visual design sheets, not production atlases. The generator returned RGB images with a baked checkerboard despite the transparency request. A background-extraction retry also failed to produce alpha. The failed retry was not selected. Do not import these as transparent sprites. Native pixel-grid redraw, palette indexing, clean alpha, aligned cells and animation production remain necessary before gameplay use. The earlier native prototype sources and runtime code are unchanged.

## Aseprite Working Documents

`assets/sources/art/style_revision/industrial_wreckage_v2.aseprite` and `assets/sources/art/style_revision/enemy_silhouettes_v2.aseprite` contain pixel-identical imports of these sheets. Each has one hidden, locked original reference layer and one visible editable working copy. They are single-frame RGB working documents, not reconstructed component layers or animation masters. The baked checkerboard remains. Both files were reopened and their visible render compared pixel-for-pixel with the original PNG.

The reusable style prompt and migration contract are in `docs/dark_space_generation_style.md`. The original user screenshot is preserved as `itch_style_reference.png` so the recipe does not depend on a temporary clipboard path.
