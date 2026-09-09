# Layered Background Variants — 2026-09-08

## Format Correction

The project has two existing formats: the GIMP source `assets/sources/world/background.xcf` is 1920×1080, while `scenes/world/background.tscn` consumes two 1600×1200 textures across three ParallaxLayers. The first generated variants matched the separate nine-layer Aseprite master, not the GIMP source or the two-texture runtime layout. Both alternatives are now supplied explicitly.

- **1920×1080, nine layers:** `assets/sources/world/background_variants_1920x1080/{red_rift,frozen_graveyard,violet_orbit}.aseprite`. Separate PNGs and catalog: `assets/sprites/world/parallax_variants_1920x1080/`. Composed previews: `assets/art/sprite_references/background_variants/widescreen/`. Cloud matter is sampled to a 384×216 logical grid; object placements are recomposed and planets/debris retain their pixel dimensions. No whole-image stretching.
- **1600×1200, two textures:** `assets/sources/world/background_compatibility/{red_rift,frozen_graveyard,violet_orbit}.aseprite`. Each variant exports `background.png` and `background_2.png` under `assets/sprites/world/background_compatibility/<variant>/`. The first packs nebulae, planets, ruins, debris and near stars; the second packs far/mid stars for reuse by b2/b3. This matches file count and dimensions but intentionally sacrifices independent nine-layer scroll control.

Existing scene settings remain unchanged: 0.75 sprite scale, 1200×900 mirroring, and motion ratios 1.1 / 0.8 / 0.5. The original textures and scene were not overwritten. The compatibility textures have transparent edges on all four sides; widescreen layers are prepared for vertical repeat. Validation passed for all six native masters, all 33 matching exports, dimensions, layer counts and repeat boundaries. Runtime integration and visual playback in the existing scene remain untested.

## Original 1600×1200 Nine-Layer Set

Three preparation backgrounds extend the existing 1600×1200, nine-layer parallax master. The original master and its current exports remain unchanged. No scenes, scripts, TileSets or gameplay integration changed.

| Variant | Native master | Direction |
|---|---|---|
| Red Rift / Faille rouge | `assets/sources/world/background_variants/red_rift.aseprite` | Crimson side currents with taller industrial wreck columns |
| Frozen Graveyard / Cimetière glacé | `assets/sources/world/background_variants/frozen_graveyard.aseprite` | Asymmetric cold dust banks, dispersed wrecks and blue planets |
| Violet Orbit / Orbite violette | `assets/sources/world/background_variants/violet_orbit.aseprite` | Broken violet crescents, ringed planets and sparse ruins |

## Layers and Exports

Each master has one frame and nine editable layers, matching the original names and back-to-front order. Every layer is exported as a full-canvas transparent 1600×1200 PNG under `assets/sprites/world/parallax_variants/<variant>/`.

| Order | Layer | Filename | Suggested vertical scroll ratio |
|---:|---|---|---:|
| 1 | Far Stars | `far_stars.png` | 0.08 |
| 2 | Nebula Blue Haze | `nebula_blue_haze.png` | 0.12 |
| 3 | Nebula Mauve Haze | `nebula_mauve_haze.png` | 0.16 |
| 4 | Nebula Filaments | `nebula_filaments.png` | 0.20 |
| 5 | Distant Planets | `distant_planets.png` | 0.24 |
| 6 | Mid Stars | `mid_stars.png` | 0.35 |
| 7 | Orbital Ruins | `orbital_ruins.png` | 0.50 |
| 8 | Distant Debris | `distant_debris.png` | 0.65 |
| 9 | Near Stars | `near_stars.png` | 0.90 |

The two historical haze names identify slots, not the actual hue of every variant. The machine-readable catalog records names, order, dimensions, source paths and suggested ratios. Ratios are starting points for later testing, not installed runtime settings.

Composite over Void `#06070c` using normal alpha blending and nearest-neighbor filtering. Nebula layers contain deliberately saturated RGB colors at low alpha; do not judge them with alpha ignored. Full compositions in `assets/art/sprite_references/background_variants/` show the intended dark base. The Aseprite masters remain transparent so all nine layers can be exported independently.

## Composition and Repeat

Most cloud matter, ruins and planets stay peripheral. Star positions, planet arrangements, ruin placement and nebula shapes vary between versions. Cloud shapes come from three separately generated material plates, not a simple hue replacement. Material was sampled on a 320×240 grid and expanded to the working canvas for deliberate coarse cloud clusters. Ruins reuse the recent faded industrial column tiles; smaller debris uses the existing test library. Repeated column pieces are still visible repetitions rather than unique wrecks.

All layers have matching fully transparent first/last rows. A 64-pixel alpha taper on full-height cloud/star layers prepares vertical repeat transitions; peripheral objects remain away from the boundary. Horizontal repeat is not guaranteed. Matching seam pixels does not prove that a repeated interval is imperceptible during long gameplay; review scroll speed and repetition in context.

## Previews and Provenance

- `assets/art/sprite_references/background_variants/comparison.png`: red, blue, violet from left to right.
- `comparison.gif`: 24-frame, 100 ms-per-frame parallax demonstration at quarter resolution. The GIF intentionally resets after the short demonstration; this reset is not the texture seam.
- `assets/sources/art/background_variants_comparison.aseprite`: editable animated comparison.
- `assets/art/sprite_references/background_variants/generation.json`: exact prompts and generation method (built-in image_gen).
- `materials/`: original generated nebula plates, preserved before native layer preparation.

## Verification

All three masters were reopened and checked for exactly nine layers in the expected order. All 27 source-layer renders matched their PNG exports pixel-for-pixel, and their top/bottom rows were checked for zero alpha. Static compositions were inspected on Void, including a correction to ensure the preview actually composites alpha over its dark background. No full-game readability or performance test was performed; these are preparation assets for later tests. No new commit was requested for this pass.
