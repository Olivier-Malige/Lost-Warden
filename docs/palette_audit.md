# Palette export audit — 2026-09-12

## Scope and result

Read-only RGB inspection of all 203 PNGs currently under `assets/sprites/`, including legacy art, alternate backgrounds and preview images. Against Lost Warden 64, 176 pass and 27 contain visible RGB values outside the shared library. This is a working-tree snapshot, including ongoing player edits; it is not a count of active runtime textures.

The 53 PNGs currently present in the four combat/player/enemy/effect `animation_rework` directories all pass. The current `nomad-red.png` and `nomad-blue.png` already used the original 24-color palette. Both recently edited player projectile sheets used eight RGB colors absent from that palette: `#8F1625`, `#C82436`, `#FF3D45`, `#FF6842`, `#113A75`, `#216BC2`, `#42B8FF`, `#7AD9FF`. These coherent red/blue energy ramps are now included verbatim in Lost Warden 64. All four current Nomad/projectile PNGs therefore pass without recoloring.

## Remaining exceptions

Percentages count pixels with alpha greater than zero, without weighting by opacity. Hidden RGB in fully transparent pixels is ignored.

| PNG | Visible RGB exceptions |
|---|---|
| `assets/sprites/combat/green_laser.png` | 2/2 colors outside palette; 10/10 visible pixels (100.0%) |
| `assets/sprites/combat/interceptor_laser.png` | 3/3 colors outside palette; 13/13 visible pixels (100.0%) |
| `assets/sprites/combat/interceptor_side_laser.png` | 2/2 colors outside palette; 5/5 visible pixels (100.0%) |
| `assets/sprites/combat/turret_shot.png` | 2/2 colors outside palette; 12/12 visible pixels (100.0%) |
| `assets/sprites/enemies/mother_ship.png` | 10/11 colors outside palette; 2375/2810 visible pixels (84.5%) |
| `assets/sprites/player/player.png` | 6/7 colors outside palette; 576/720 visible pixels (80.0%) |
| `assets/sprites/player/player2_shot.png` | 3/3 colors outside palette; 118/118 visible pixels (100.0%) |
| `assets/sprites/player/player2_side_shot.png` | 3/3 colors outside palette; 33/33 visible pixels (100.0%) |
| `assets/sprites/player/shield_sheet.png` | 2/3 colors outside palette; 140/220 visible pixels (63.6%) |
| `assets/sprites/player/x_wing.png` | 6/7 colors outside palette; 576/720 visible pixels (80.0%) |
| `assets/sprites/world/background.png` | 6/6 colors outside palette; 1728/1728 visible pixels (100.0%) |
| `assets/sprites/world/background_2.png` | 5/5 colors outside palette; 928/928 visible pixels (100.0%) |
| `assets/sprites/world/background_compatibility/frozen_graveyard/background.png` | 9639/9651 colors outside palette; 444166/483864 visible pixels (91.8%) |
| `assets/sprites/world/background_compatibility/red_rift/background.png` | 22542/22549 colors outside palette; 592552/594919 visible pixels (99.6%) |
| `assets/sprites/world/background_compatibility/violet_orbit/background.png` | 16400/16410 colors outside palette; 280242/316388 visible pixels (88.6%) |
| `assets/sprites/world/debris_corridor/vertical_debris_faded_atlas.png` | 3881/3882 colors outside palette; 36341/36350 visible pixels (100.0%) |
| `assets/sprites/world/light.png` | 1/1 colors outside palette; 193/193 visible pixels (100.0%) |
| `assets/sprites/world/light_2.png` | 1/1 colors outside palette; 6140/6140 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants/frozen_graveyard/orbital_ruins.png` | 3881/3882 colors outside palette; 70930/70948 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants/red_rift/orbital_ruins.png` | 3881/3882 colors outside palette; 96348/96372 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants/violet_orbit/orbital_ruins.png` | 3881/3882 colors outside palette; 71806/71824 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants_1920x1080/frozen_graveyard/orbital_ruins.png` | 3881/3882 colors outside palette; 70930/70948 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants_1920x1080/red_rift/orbital_ruins.png` | 3881/3882 colors outside palette; 96348/96372 visible pixels (100.0%) |
| `assets/sprites/world/parallax_variants_1920x1080/violet_orbit/orbital_ruins.png` | 3881/3882 colors outside palette; 71806/71824 visible pixels (100.0%) |
| `assets/sprites/world/starfield_variant/background.png` | 6/6 colors outside palette; 1728/1728 visible pixels (100.0%) |
| `assets/sprites/world/starfield_variant/background_2.png` | 5/5 colors outside palette; 928/928 visible pixels (100.0%) |
| `assets/sprites/world/starfield_variant/preview.png` | 11/12 colors outside palette; 664/480000 visible pixels (0.1%) |

## Follow-up and limits

- Audit each remaining asset's current scene usage before prioritizing changes: this list includes old files and previews, not only active art.
- For an asset retained in production, adjust its editable source and regenerate its export together. Check readability beside the current Nomad and hostile ships. No artwork was automatically quantized in this pass.
- The native Aseprite palettes and cel pixels have not been audited or updated. Load `assets/palettes/lost_warden_64.gpl` in the masters before future editing and check exported colors afterward.
- Palette membership does not validate silhouettes, animation continuity, faction roles, binary alpha or in-game contrast. Runtime modulation and alpha blending may also change displayed colors.
- Reproduce the audit with `python scripts/art/audit_palette.py`. Exit code 1 is expected while the listed exceptions remain.
