# Lost Warden — Armored Industrial Pixel Art

## Accepted Direction

The maintainer accepted the generated v2 wreckage and enemy sheets on 2026-09-08. They establish a richer direction than the earlier flat test prototypes: angular silhouettes, layered dark armor, recessed machinery, broken internal structure, restrained worn edges and sparse red accents.

## Reproduction Inputs

Use the built-in image_gen tool with these repository-local image references:

- `assets/art/sprite_references/style_revision/itch_style_reference.png`: original visual reference supplied by the maintainer.
- `assets/art/sprite_references/style_revision/industrial_wreckage_v2.png`: accepted wreckage direction.
- `assets/art/sprite_references/style_revision/enemy_silhouettes_v2.png`: accepted enemy direction.

`assets/art/sprite_references/style_revision/generation.json` preserves the exact two successful design prompts. Generations are not deterministic; the prompt alone does not guarantee matching sprites. Attach the relevant accepted sheet with every new generation.

## Reusable Style Prompt

```text
Create [ASSET DESCRIPTION] for the dark-space shmup Lost Warden.
Input 1: original itch.io style reference.
Input 2: accepted industrial wreckage or enemy sheet, used as the material and detail benchmark.
[Optional Input 3: existing sprite to restyle; preserve its identity and silhouette.]

Top-down orthographic pixel art. Angular industrial silhouettes with overlapping
charcoal armor, recessed technical panels, deep cavities, exposed structural ribs
and restrained worn gunmetal edges. Build convincing volumes with deliberate
hard pixel clusters and occlusion. Avoid flat rectangular icons, uniform outlines,
micro-noise, smooth gradients, soft shading and 3D-rendered surfaces.

Keep hulls mostly near #101522 and #222735, with #464a52 structure and sparse
#74777d worn edges. Use #3a0d14 and #9c2020 for recessed red panels, with tiny
#ff5a4d signal slits. Preserve functional color roles for allied sprites, shields
and pickups instead of making every asset red. No broad luminous hull outlines.

[LAYOUT: subject count, fixed cell dimensions, orientation, margins and poses.]
Keep every asset fully inside its own cell, without overlaps. No text, logo,
nebula, stars, grid lines or background shadows. Request a genuine transparent
RGBA background, including holes; never paint a checkerboard into the image.
```

## Restyling Existing Sprites

Adapt by family rather than running a global filter. Supply the original source/export as an identity reference, then use the accepted v2 sheet as the style reference. Preserve the original canvas, frame count, pivot, orientation, tag ranges and durations for a drop-in replacement. If the added detail needs a larger logical grid, produce a separate version and record the scaling/integration change explicitly.

- Enemy hulls: layered armor, recessed weapon bays, restrained red faction marks; retain each role's silhouette.
- Player: retain red/blue team identity and recognizable banking poses; add panel depth without hiding the cockpit.
- Carrier and boss: emphasize hull masses, internal bays and structural ribs, with sparse highlights.
- Wreckage: asymmetric breaks and exposed internals; keep backdrop debris quieter than active enemies.
- Pickups and effects: preserve readable symbols and functional accent colors; do not impose dense hull textures on small flashes or glyphs.

Treat a generated sheet as a design input. It does not automatically preserve an exact palette, pixel grid, animation layout or transparent alpha. Verify those properties, then author native layers and animation continuity in Aseprite before treating the result as a production replacement. This recipe authorizes no runtime changes or roadmap phase implementation.

## Current Files and Limits

The two v2 sheets are RGB images with a baked checkerboard. A transparency retry failed. Aseprite working copies are available under `assets/sources/art/style_revision/`, with the original hidden and locked and a visible editable copy. Importing a flattened PNG does not reconstruct armor, lighting or animation layers. These working files preserve the accepted visuals and need native production preparation before gameplay use.
