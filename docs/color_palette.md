# Lost Warden 64 color palette

`Lost Warden 64` is the shared source of truth for new UI and sprite work as of 2026-09-12. It extends the original palette with intermediate material shades and complete energy ramps. The first 24 entries keep their exact RGB values and indices; `lost_warden_24.gpl` remains a historical reference.

- Importable palette: `assets/palettes/lost_warden_64.gpl`.
- Plain hex list: `assets/palettes/lost_warden_64.hex`.
- Labeled swatches: `assets/palettes/lost_warden_64.svg`.
- Current export audit and remaining exceptions: `docs/palette_audit.md`.

## Shared colors

Transparency is separate from the 64 RGB colors. Different sprites use different subsets of this library; consistency means shared material ramps and color roles, not identical subsets everywhere.

| ID | Name | Hex |
|---:|---|---|
| 00 | Void | `#06070C` |
| 01 | Deep Space | `#101522` |
| 02 | Hull Shadow | `#222735` |
| 03 | Gunmetal | `#464A52` |
| 04 | Steel | `#74777D` |
| 05 | Pale Steel | `#B8B6AE` |
| 06 | Star White | `#F3EBDD` |
| 07 | Oxblood | `#3A0D14` |
| 08 | Warden Red | `#9C2020` |
| 09 | Ember | `#E15A43` |
| 10 | Dark Bronze | `#442D18` |
| 11 | Amber | `#9E6B2D` |
| 12 | Solar | `#D6D653` |
| 13 | Deep Ion | `#102A4A` |
| 14 | Ion Blue | `#2D6594` |
| 15 | Ice Blue | `#78B7CF` |
| 16 | Neon Red | `#FF5A4D` |
| 17 | Neon Gold | `#FFD35A` |
| 18 | Plasma Cyan | `#72E0D1` |
| 19 | Shield Violet | `#B979C8` |
| 20 | Pickup Green | `#72C95C` |
| 21 | Hazard Orange | `#FF9D32` |
| 22 | Laser Pink | `#F05A9D` |
| 23 | Flash White | `#FFF8E8` |
| 24 | Recess | `#171C2A` |
| 25 | Dark Plate | `#323846` |
| 26 | Brushed Steel | `#5D626D` |
| 27 | Silver Plate | `#92969C` |
| 28 | Ivory Edge | `#D6D1C5` |
| 29 | Crimson Depth | `#621521` |
| 30 | Pulse Red Shadow | `#8F1625` |
| 31 | Pulse Red | `#C82436` |
| 32 | Pulse Red Light | `#FF3D45` |
| 33 | Pulse Coral | `#FF6842` |
| 34 | Umber Depth | `#2C211B` |
| 35 | Aged Bronze | `#654325` |
| 36 | Warm Copper | `#BF883D` |
| 37 | Hot Amber | `#EDB64B` |
| 38 | Pale Gold | `#FFE6A0` |
| 39 | Cobalt Hull | `#1D466D` |
| 40 | Pulse Blue Shadow | `#113A75` |
| 41 | Pulse Blue | `#216BC2` |
| 42 | Pulse Blue Light | `#42B8FF` |
| 43 | Pulse Ice | `#7AD9FF` |
| 44 | Abyss Teal | `#0D3039` |
| 45 | Reactor Teal | `#185460` |
| 46 | Oxidized Teal | `#287F88` |
| 47 | Ion Teal | `#48ADB0` |
| 48 | Pale Cyan | `#B4F1DF` |
| 49 | Void Violet | `#21182E` |
| 50 | Violet Shadow | `#3C2A4D` |
| 51 | Violet Plate | `#60436E` |
| 52 | Violet Midlight | `#8C619B` |
| 53 | Pale Violet | `#D8A5DC` |
| 54 | Forest Shadow | `#172B24` |
| 55 | Moss Plate | `#2C4B35` |
| 56 | Muted Green | `#476F43` |
| 57 | Leaf Green | `#5B984C` |
| 58 | Pale Green | `#B2E58B` |
| 59 | Wine Shadow | `#35182C` |
| 60 | Wine Plate | `#61263F` |
| 61 | Magenta Midtone | `#963758` |
| 62 | Rose Light | `#C9477B` |
| 63 | Pale Pink | `#FFA5C6` |

## Shading ramps

Read each row from shadow to highlight. Select adjacent shades as needed; do not use every shade in every sprite.

| Material or effect | Palette IDs, dark to light |
|---|---|
| Neutral hull | 00, 01, 24, 02, 25, 03, 26, 04, 27, 05, 28, 06 |
| Red hull | 07, 29, 08, 09, 06 |
| Red pulse | 30, 31, 32, 33, 23 |
| Bronze / rock | 34, 10, 35, 11, 36, 37, 38 |
| Blue hull | 13, 39, 14, 15, 06 |
| Blue pulse | 40, 41, 42, 43, 23 |
| Teal / reactor | 44, 45, 46, 47, 18, 48, 23 |
| Violet / shield | 49, 50, 51, 52, 19, 53, 23 |
| Green / pickup | 54, 55, 56, 57, 20, 58 |
| Pink / exotic energy | 59, 60, 61, 62, 22, 63, 23 |
| Explosion | 07, 08, 09, 21, 17, 38, 23 |

## Production rules

- Use about 8-16 colors for a standard ship, selected from the shared ramps. Smaller effects can use 3-6; larger bosses and scenery can use more when their materials need it. These are working ranges, not hard limits.
- Use at least a shadow, a midtone and a highlight for a readable material. Keep deeper recesses and narrow structural edges distinct.
- Keep bright emissive accents localized, generally under ten percent of a normal hull. Preserve dark hulls against the space background.
- Use hard pixel clusters and deliberate dithering. Do not add arbitrary RGB shades through antialiasing or smooth gradients.
- Keep combat sprite alpha binary. Background layers may use partial alpha; their visible source RGB must still come from the palette. Runtime blending, lighting and modulation can produce other screen colors and are not assessed by an export RGB audit.
- Keep the current red/blue Nomad team markings. Red and blue pulse colors 30-33 and 40-43 are taken exactly from the current player projectile exports, making those existing effects part of the common library.
- Palette membership does not by itself guarantee faction readability. Compare the player, enemies, projectiles and background together at gameplay scale.
- Load the shared palette in each editable source and verify its matching PNG after export. Merely loading a palette does not recolor existing RGB pixels.
- Do not batch-quantize existing artwork. Correct a source and its matching export together, preserving clusters, alpha, frame layout, tags and pivots.

## Export validation

Requires Python and Pillow. Run from the repository root:

```sh
python scripts/art/audit_palette.py assets/sprites/player/nomad-red.png assets/sprites/player/nomad-blue.png assets/sprites/player/player_shot.png assets/sprites/player/player_side_shot.png
python scripts/art/audit_palette.py
```

Exit code 0 means every visible RGB value belongs to the palette; 1 reports exceptions. Fully transparent pixels are ignored. The checker does not modify files or validate editable sources, animation, alpha rules, scene reachability, or visual quality.

## Historical benchmark

The following records the earlier 24-color pass. The 64-color specification above supersedes its palette-size constraint.

## Dark Space Application — Accepted Benchmark

The 2026-09-07 harmonization retains all 24 palette entries. On Dominion hulls, prioritize Deep Space and Hull Shadow over broad Steel/Pale Steel surfaces. Keep brighter edges short and structural. Elite violet appears in localized markings rather than complete outlines; red aura layers remain hidden in the revised sources.

Asteroids use the original-shape Dark Slate variant with sparse bronze/amber minerals. Scenery uses muted rings, low-alpha blue and Warden-red nebula layers, and restrained warm stars. Preserve bright projectile cores, impacts, and interaction cues instead of darkening every asset uniformly.

The produced Nomad variants retain their existing red/blue team markings and projectile colors. This pass does not implement the separate proposed change to allied-fire color semantics. See `dark_space_art_review.md` for the current scope and validation limits.
