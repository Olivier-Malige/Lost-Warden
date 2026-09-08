# Gameplay Test Sprite Library

Date: 2026-09-08. Preparation assets only. No scenes, gameplay scripts, collision shapes, enemy definitions or roadmap phases were implemented in this production pass. Earlier runtime feedback changes remain in the working tree.

## Export Contract

- Editable RGB Aseprite sources with named layers and tags; transparent horizontal PNG sheets with no spacing or trimming.
- Lost Warden 24 colors, hard pixel edges and binary transparency. Use nearest-neighbor filtering.
- JSON catalogs beside the sheets give cell dimensions, anchors, frame counts and timing. JSON frame indices are zero-based; Aseprite uses one-based indices.
- Effects are overlays without a baked-in ship. Muzzle effects face up; propulsion extends down from its anchor. Rotate at integration as needed. Shields use a fixed center; the hit variant is authored on the right side.
- Burst effects end transparent; play once. Loops repeat; debris rotations are eight authored poses, not physics simulation. Charge effects are finite build-ups, requiring a deliberate transition to a weapon effect.
- Enemy sources face down and have a common animation layout. These are test-ready art prototypes derived from local future-enemy references, not approved new enemy behavior.
- Debris modules are static alternatives, not animation frames. Their visible centers vary deliberately within a shared 64×64 placement cell. No collision polygons are supplied.

## Effects

Sources: `assets/sources/effects/test_library/`. Sheets and machine-readable catalog: `assets/sprites/effects/test_library/`. Individual animated previews: `assets/art/sprite_references/effect_library/`.

| # | Name | Cell | Frames | Frame time | Playback | Anchor |
|---:|---|---|---:|---:|---|---|
| 1 | `impact_metal` | 32×32 | 7 | 40 ms | Once | (16, 16) |
| 2 | `impact_energy` | 32×32 | 7 | 40 ms | Once | (16, 16) |
| 3 | `impact_armor` | 32×32 | 7 | 40 ms | Once | (16, 16) |
| 4 | `impact_asteroid` | 32×32 | 7 | 40 ms | Once | (16, 16) |
| 5 | `pickup_gold` | 32×32 | 8 | 60 ms | Once | (16, 16) |
| 6 | `pickup_blue` | 32×32 | 8 | 60 ms | Once | (16, 16) |
| 7 | `pickup_green` | 32×32 | 8 | 60 ms | Once | (16, 16) |
| 8 | `pickup_cyan` | 32×32 | 8 | 60 ms | Once | (16, 16) |
| 9 | `shield_activate` | 48×48 | 8 | 60 ms | Once | (24, 24) |
| 10 | `shield_hit` | 48×48 | 7 | 40 ms | Once | (24, 24) |
| 11 | `shield_break` | 48×48 | 9 | 60 ms | Once | (24, 24) |
| 12 | `muzzle_single` | 24×32 | 6 | 40 ms | Once | (12, 24) |
| 13 | `muzzle_double` | 24×32 | 6 | 40 ms | Once | (12, 24) |
| 14 | `muzzle_plasma` | 24×32 | 6 | 40 ms | Once | (12, 24) |
| 15 | `charge_small` | 48×48 | 10 | 60 ms | Once | (24, 24) |
| 16 | `charge_heavy` | 48×48 | 10 | 60 ms | Once | (24, 24) |
| 17 | `charge_overload` | 48×48 | 10 | 60 ms | Once | (24, 24) |
| 18 | `damage_electric` | 32×40 | 8 | 80 ms | Loop | (16, 20) |
| 19 | `damage_embers` | 32×40 | 8 | 80 ms | Loop | (16, 20) |
| 20 | `damage_reactor_leak` | 32×40 | 8 | 80 ms | Loop | (16, 20) |
| 21 | `debris_hull` | 32×32 | 8 | 100 ms | Loop | (16, 16) |
| 22 | `debris_wing` | 32×32 | 8 | 100 ms | Loop | (16, 16) |
| 23 | `debris_mechanical` | 32×32 | 8 | 100 ms | Loop | (16, 16) |
| 24 | `thruster_idle` | 24×40 | 8 | 70 ms | Loop | (12, 6) |
| 25 | `thruster_boost` | 24×40 | 8 | 70 ms | Loop | (12, 6) |
| 26 | `thruster_damaged` | 24×40 | 8 | 70 ms | Loop | (12, 6) |

The effect overview follows this order left-to-right, top-to-bottom, eight columns. Its synchronized 80 ms display is for comparison; individual GIFs and the catalog retain each asset’s authored timing. The preview background is not present in the transparent sheets.

## Industrial Wreckage

Visual reference: local `assets/art/itch/lost_warden_page_background_v3_banner_palette.png`, particularly broken structural beams, recessed panels and exposed conduits. These modules were authored as separate dark industrial silhouettes; the page nebula and background are not baked in.

Source: `assets/sources/world/test_library/industrial_wreckage.ase`. Sheet: `assets/sprites/world/test_library/industrial_wreckage_sheet.png` (768×64). Preview: `assets/art/sprite_references/industrial_wreckage.png`, four columns.

| Frame | Variant |
|---:|---|
| 0 | `broken_truss` |
| 1 | `hull_bulkhead` |
| 2 | `conduit_elbow` |
| 3 | `orbital_ring` |
| 4 | `radiator_panel` |
| 5 | `engine_wreck` |
| 6 | `cargo_frame` |
| 7 | `antenna_mast` |
| 8 | `severed_wing` |
| 9 | `reactor_cage` |
| 10 | `docking_arm` |
| 11 | `armor_cluster` |

## Enemy Prototypes

Sources and sheets live under `assets/sources/enemies/test_library/` and `assets/sprites/enemies/test_library/`. Each source has Hull, Markings and Wear, Engine and Weapon, and Destruction layers.

| Name | Cell | Sheet | Visual role |
|---|---|---|---|
| Furnace Bomber | 32×32 | 448×32 | Broad twin furnace pods |
| Lance Sniper | 32×48 | 448×48 | Narrow central cannon |
| Dive Hunter | 32×32 | 448×32 | Swept wings and pointed nose |

All frames last 80 ms. Inclusive zero-based ranges: idle 0–2 (loop), charge 3–4, fire 5, hit 6, damaged 7 (hold), explode 8–13 (once, ending transparent). Full-sheet GIFs are inspection reels through every state, not a recommended gameplay state sequence. Destruction is a provisional reusable treatment for testing.

## Validation

- All 26 effect exports passed size, palette, binary-alpha and transparent burst-ending checks.
- All three enemy sheets passed the 14-frame layout, palette and transparent destruction-ending checks.
- The wreckage sheet contains 12 distinct 64×64 cells.
- Native previews were inspected for silhouette and structure. The sources and exports are checked for pixel agreement.
- No gameplay integration or in-game readability claim is made. Select scale, attachment points, collisions and animation transitions during the later integration phase.
