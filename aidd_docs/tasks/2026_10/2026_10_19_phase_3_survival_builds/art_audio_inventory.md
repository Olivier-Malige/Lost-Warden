# Phase 3 verified art and audio inventory

Inspected 2026-10-20 at step 1; baseline inspection tables are retained below. Steps 3-4 deliveries are recorded separately: the playable foundation now has paired UI/pickup artwork and refreshed laser exports. Paths are repository-relative. Later offensive-effect targets are still unproduced. The [contract](contract.md) owns mechanics and delivery gates.

## Native baseline and approved direction

- `project.godot`: 640x400 viewport, nearest texture sampling. Use `assets/palettes/lost_warden_64.gpl`, crisp clusters and integer placement for new art. Historical x4 production instructions in the general inventory do not apply to Phase 3.
- Active HUD is embedded in `scenes/world/world.tscn`, with `scenes/ui/hud.gd`; there is no separate hud.tscn. It uses `assets/fonts/slkscr.ttf` at size 12, 104-pixel side rails, style-box plasma bars and text ranks. Existing energy pips use `assets/ui/player1_energy.png` / `player2_energy.png` and `assets/sources/player/player_energy_master.ase` (32x32, one frame, team layers).
- The maintainer approved the interactive preview on 2026-10-20, with **Arsenal déployé** selected: three horizontal cards in solo, independent stacked cards per player in co-op. Preserve that direction at the native UI checkpoint; verify exact typography, coordinates and wide-window behavior there. The preview is a silent interaction reference, not runtime evidence or final sprites.
- P1 red / P2 blue remain the ownership convention. Use shape, player labels and ranks as well as color. XP and plasma are shared collectible types, not owned projectiles.

## Active foundation dependencies — step 1 baseline

Pivots are centered Sprite2D cell origins unless stated otherwise. Bounds use `[left, top, right, bottom)` in cell pixels and exclude procedural halos. Scene offsets below are current facts to preserve during art work, not an instruction to introduce fractional placement in new components.

| Asset / active consumer | Runtime export and layout | Editable master and tags | Footprint / pivot / ownership | Checkpoint |
| --- | --- | --- | --- | --- |
| Primary cannon: `data/weapons/primary.tres` → `scenes/player/player_shot.tscn` | `assets/sprites/player/player_shot.png`, 80x16, 5x2 cells of 16x8. P1 frames 0-4; P2 5-9; small/normal/big/large/full. Static tiers, not a flow loop. | `assets/sources/player/pulse_shot_primary_master.ase`: 16x16 canvas, five frames, 100 ms metadata, one `Flattened` layer. Tags small 0, normal 1, big 2, large 3, full 4. Each source frame contains both 8-pixel team rows. | Center (8,4); sprite offset (0,-3.3333333), collision 10x6 at (0,-4.3333333). Visible tiers: 10x6, 10x7, 10x8, 12x8, 12x8. Red top row / blue bottom. Glow is separate through `projectile_vfx_config.tres`. | Step 4 refresh source + same export layout. No collision change. |
| Side cannon: `data/weapons/side.tres` → `scenes/player/player_side_shot.tscn` | `assets/sprites/player/player_side_shot.png`, 30x16, 5x2 cells of 6x8, same team/tier indexing as primary. | `assets/sources/player/pulse_shot_side_master.ase`: 6x16, five frames, 100 ms; same five tags; Player Red / Player Blue / Core layers. Source frames contain both team rows. | Center (3,4); sprite offset (0,-0.66666667); root offset (0,-3.3333333); collision 2x3 at (0,-2.1666667). Visible tier bounds (2,1,4,4), (1,1,5,5), (1,1,5,6), (0,1,6,7), (0,0,6,8), same in both rows. Separate behind-sprite glow through `side_projectile_vfx_config.tres`. | Step 4 refresh; keep all five atlas tiers even though new gameplay has four ranks. Map rank/tier explicitly on activation. |
| Signature beam: `scenes/player/beam/continuous_beam.tscn`, `.gd`, `beam_flow.gdshader` | `assets/sprites/player/beam.png`, 320x16: 20 columns of 16x8, P1 top / P2 bottom. Five tiers, four flow frames per tier; shader uses tier 2 normally and tier 4 in overdrive. | `assets/sources/player/plasma_beam_master.ase`: 16x16, 20 frames. Tags small 0-3, normal 4-7, big 8-11, large 12-15, full 16-19. Source durations 80 ms. Red Halo / Red Energy / Blue Halo / Blue Energy / Core. | Line origin is emitter, extending upward to first obstacle. Authored widths 4/6/8/12/16; live widths 8 / 16, collision width x1.2 (9.6 / 19.2). Alpha fills cell height 8. Halo width x1.35. Runtime flow duration is **160 ms**, not the source's 80 ms. | Step 4 preserve source/layout, manual reserve and normal/overdrive identity. No beam unlock icon. |
| Reflector: `scenes/player/shield.tscn`, instanced by player.tscn | `assets/sprites/player/shield.png`, 96x40, 6x4 cells of 16x10. Rows: P1 idle, P1 reflect, P2 idle, P2 reflect. | `assets/sources/player/nomad_shield_master.ase`: 16x10, 24 frames, 100 ms; tags player1_idle 0-5, player1_reflect 6-11, player2_idle 12-17, player2_reflect 18-23. Backing / team / impact-return layers. | Visible idle width 4→16 and height 3→6; reflection includes return trail up to 16x9. Cell center (8,5); sprite offset (-0.0182495,0.5578375). Collision 4x3 at (-0.018249501,3.0578375). Standalone root scale 4 is overridden to **1** in player.tscn. | Retain existing sprite/behavior; reward icon Step 3, three-charge migration Step 4. Do not infer new collision size from the standalone scene. |
| Plasma pickup: `scenes/ui/plasma_cell.tscn` | `assets/sprites/pickups/power_up.png`, 128x16, eight 16x16 cells; frame 7. | `assets/sources/pickups/power_up_master.ase`: 16x16, eight frames; damage/speed/repair/side_shot/shield/beam/fire_rate/plasma_cell tags at 0-7. Dark Casing / Pickup Symbol / Status Light layers. | Center (8,8), full 16x16 alpha bounds, no sprite offset. Collision 14x14 at origin; notifier 10x10. Shared plasma event; not a P1/P2 sprite. | Step 4: create `assets/sources/pickups/plasma_cell.aseprite` → `assets/sprites/pickups/plasma_cell.png`; retain 16x16 cell and collision, migrate texture before dropping the legacy atlas dependency. |

Measurements cover PNG alpha bounds and Aseprite headers/tags/layers; they do not prove source/export pixel equality. Check reproducible exports during each art delivery. Weapon rotations, glows and animated shield offsets also require native in-game evidence at that checkpoint.

Collision animation tracks override the scene defaults above. For both teams, primary small/normal/big/large/full shapes are 10x6 / 10x7 / 10x8 / 12x8 / 12x8, at y -4.3333333 / -3.8333333 / -3.3333333 / -3.3333333 / -3.3333333. Side shapes are 2x3 / 4x4 / 4x5 / 6x6 / 6x8, at y -2.1666667 / -1.6666667 / -1.1666667 / -0.66666669 / -0.66666669, relative to the projectile root. Shield levels use 4x3 / 6x3 / 8x4 / 10x4 / 12x5 / 16x6, at y 3.0578375 / 3.0578375 / 2.5578375 / 2.5578375 / 2.0578375 / 1.5578375 with x -0.018249501. The player's shield instance is positioned at (0,-19.5). Reflection trails and ThrowbackEcho do not enlarge these contact shapes. Preserve this animation mapping as well as default shapes.

## Libraries are not active replacements

No `scenes/` or `data/` reference was found to the following four player `animation_rework` atlases. Their corresponding sources live under `assets/sources/player/animation_rework/`. JSON metadata is beside each PNG under `assets/sprites/player/animation_rework/`.

| Library | Measured export / metadata | Reuse rule |
| --- | --- | --- |
| pulse_shot_primary_sheet | 64x64, 25 frames, 8x16 source cells. Five static tags 0-4; four-frame small_flow/normal_flow/big_flow/large_flow/full_flow at 5-24. | Different orientation/cell from live 16x8. Reauthor/export into the retained 5x2 grid if a treatment is reused; do not swap textures. |
| pulse_shot_side_sheet | 32x64, 25 frames, 4x16 source cells, same static/flow tags. | Different width and orientation from live 6x8; no automatic reuse mapping. |
| plasma_beam_sheet | 128x48, 20 frames, 16x16 cells; same five four-frame tags. | Packed full-team source frames are not the shader's 320x16 team-row atlas. Preserve active export. |
| nomad_shield_sheet | 128x90, 72 frames, 16x10 cells; original tags 0-23 plus six four-frame reflect_level tags per team at 24-71. | Live 6x4 frame indexing cannot address this sheet. Keep active shield; extra reflect animation is deferred. |

`player2_shot.png`, `player2_side_shot.png` and `shield_sheet.png` also have no scene/data references in this scan. Do not revive them. Existing effect-library sprites may serve as references only after a documented source/tag mapping; no broad enemy-effect integration is part of this phase.

## Foundation production batches — initial targets

The agent owns art production/export/integration and native visual evidence. The maintainer reviews readability/style. These are the **initial step-1 targets**; delivered step-3/4 mappings below supersede proposed split UI paths. Keep palette and team identity above. Sources use Aseprite, exports nearest PNG plus frame/tag metadata when animated. Later offensive-effect dimensions remain production briefs, subject to native visual verification without changing gameplay collision rules.

| Batch | Source → runtime destination | Frame / pivot / visual brief | Delivery |
| --- | --- | --- | --- |
| Main and side laser refresh | Existing masters → existing PNGs above | Preserve grids, tier IDs, team rows and footprints. Keep short shots legible; no mandatory flow animation. | Step 4 |
| Signature plasma | Existing master → beam.png | Preserve normal/overdrive shader mapping and distinguish the secondary from cannon shots. | Step 4 verification |
| Low/high XP | `assets/sources/pickups/xp_orbs.aseprite` → `assets/sprites/pickups/xp_orbs.png` | Proposed two 8x8 static cells, small diamond / larger faceted diamond, centered (4,4), shared amber/ivory. High-value threshold is a later explicit runtime rule, not a different XP amount. Acquisition radius stays data-owned (8 px collection). | Step 4 |
| Plasma cell | Dedicated pair above | One 16x16 static cell, centered (8,8); cyan battery silhouette distinct from amber XP. Preserve collider and pickup mechanics. | Step 4 |
| Sixteen icons | `assets/sources/ui/upgrade_icons.aseprite` → `assets/sprites/ui/upgrade_icons.png` | Proposed 8x2 grid of 16x16 cells. Fixed indices below; center (8,8), no collision. Team ownership belongs to panel/focus, not duplicated icons. | Foundation IDs Step 3; remaining IDs with their combat feature, full atlas kept stable |
| Cards and focus/ready | `assets/sources/ui/upgrade_card_states.aseprite` → `assets/sprites/ui/upgrade_card_states.png` | Proposed 16x16 nine-patch cells: idle/focus/ready for each team, indices 0-2 P1, 3-5 P2. Corner margins 4 px; text/rank labels remain real Controls. Adapt horizontal solo / stacked co-op geometry in Step 3. | Step 3 |
| Seven-slot strips | `assets/sources/ui/build_slots.aseprite` → `assets/sprites/ui/build_slots.png` | Proposed 12x12 empty offensive/utility cells at 0/1; four + three authored UI cells per player. Icons/ranks are overlays; never bake a build into art. Red/blue focus via UI. | Selection Step 3, HUD activation Step 4 |
| Shared XP bar | `assets/sources/ui/xp_bar.aseprite` → `assets/sprites/ui/xp_bar.png` | Proposed 8x4 empty/fill caps, two cells; horizontal stretch only through a native UI component. Numeric level/XP remains text, below SURVIVAL in right rail. | Step 4 |

### Stable icon cells (sixteen total)

| Index | ID | Symbol brief | Checkpoint |
| --- | --- | --- | --- |
| 0 | speed | Forward thruster chevrons | 3 |
| 1 | damage | Broad upward cannon bolt with ivory core | 3 |
| 2 | fire_rate | Three staggered upward pulses | 3 |
| 3 | orb_magnet | Cyan horseshoe around a gold XP diamond | 3 |
| 4 | side_shot | Upward-facing ship with two forward bolts above its wings | 3 |
| 5 | energy | Repair cross / energy pip | 3 |
| 6 | shield | Concave reflector | 3 |
| 7 | score | Stacked gold salvage ingots; automatic fallback, not a normal offer | 3 |
| 8 | piercing | Bolt passing through two plates | 7 |
| 9 | critical_hits | Focused impact star | 7 |
| 10 | micro_missiles | Guided rocket | 8 |
| 11 | escort_drone | Small winged escort | 9 |
| 12 | orbiting_satellites | Orbital body and ring | 10 |
| 13 | impact_explosions | Broken blast ring | 11 |
| 14 | energy_chains | Linked target nodes | 12 |
| 15 | ricochet | Angled rebound trace | 13 |

Reserve unimplemented cells as transparent; no locked/placeholder family enters the live offer catalog. Plasma is not one of these sixteen cards.

## New offensive art ownership

Every pair below is a **new target**. All team-sensitive projectiles/effects use separate red/blue frame tags with the same silhouette; all anchors and animation ranges must be recorded alongside exports before enabling the family. Integrate each ID's icon above at the same checkpoint.

| Family | Editable source → runtime export | Native brief / pivot / collision agreement | Step |
| --- | --- | --- | --- |
| piercing | `assets/sources/combat/piercing_hit.aseprite` → `assets/sprites/combat/piercing_hit.png` | Proposed 16x16 impact treatment, center (8,8); short entry/exit streak around accepted contact. Existing cannon geometry unchanged. | 7 |
| critical_hits | `assets/sources/combat/critical_impact.aseprite` → `assets/sprites/combat/critical_impact.png` | Proposed 16x16 impact star, center (8,8), ivory accent with owner edges; distinguish from piercing by shape. Visual only. | 7 |
| micro_missiles | `assets/sources/combat/micro_missile.aseprite` → `assets/sprites/combat/micro_missile.png` | Proposed 8x16 body/thrust/impact cells, center (4,8), nose upward; turn by node rotation, not resampling source. Document body vs trail bounds and match eventual direct-hit collider to body. No intrinsic splash. | 8 |
| escort_drone | `assets/sources/player/escort_drone.aseprite` → `assets/sprites/player/escort_drone.png`; `assets/sources/combat/escort_bolt.aseprite` → `assets/sprites/combat/escort_bolt.png` | Proposed 16x16 escort idle/muzzle (center 8,8) and 6x8 straight bolt (3,4). Visible offset from owner; bolt collision must fit core, not muzzle flash/trail. | 9 |
| orbiting_satellites | `assets/sources/player/orbiting_satellite.aseprite` → `assets/sprites/player/orbiting_satellite.png` | Proposed 12x12 orbit/contact cells, center (6,6); body fits 4 px contact radius. Orbit radius 32 is a mechanic, not a 64-pixel baked sprite. | 10 |
| impact_explosions | `assets/sources/combat/impact_explosion.aseprite` → `assets/sprites/combat/impact_explosion.png` | Proposed 64x64 blast cells, center (32,32), radius treatments 20/26/32; expanding broken ring, source-owned tags for ranks. Visual radius must match damage query; no scaling collider to glow. | 11 |
| energy_chains | `assets/sources/combat/energy_chain.aseprite` → `assets/sprites/combat/energy_chain.png`; `assets/sources/combat/energy_chain_anchor.aseprite` → `assets/sprites/combat/energy_chain_anchor.png` | Proposed 8x8 tileable segment (endpoints at edge midpoints) and 12x12 anchor (6,6); bounded short arc, clear owner color. Segments are rendering only; accepted target query owns damage. | 12 |
| ricochet | `assets/sources/combat/ricochet_shard.aseprite` → `assets/sprites/combat/ricochet_shard.png` | Proposed 8x8 shard/impact cells, center (4,4), angular diamond; distinguish secondary shard from original cannon. Contact body excludes impact animation. | 13 |

## Audio handoff

### Step 4 delivered foundation mapping — 2026-10-20

- `pulse_shot_primary_master.ase` → `player_shot.png` and `pulse_shot_side_master.ase` → `player_side_shot.png`: leading opaque cores refreshed with palette ivory; same five source frames/tags/team rows and 80x16 / 30x16 exports. Every alpha byte is unchanged from the pre-step baseline. Source re-export equality and Lost Warden 64 PASS. Primary visual tiers use min(DAMAGE rank,4); side ranks 1/2/3/4 map to atlas columns 0/1/2/4, retaining the unused fourth static column and existing animated collision tracks.
- `assets/sources/pickups/xp_orbs.aseprite` → `assets/sprites/pickups/xp_orbs.png`: two 8x8 source frames tagged ordinary (0) / high_value (1), horizontally exported as 16x8. The high-value silhouette is selected at value >=4, including merged value; the threshold affects presentation only. Pivot (4,4), gold/ivory shared diamonds; actual collection distance remains 8 px between centers.
- `assets/sources/pickups/plasma_cell.aseprite` → `assets/sprites/pickups/plasma_cell.png`: one 16x16 frame/tag plasma_cell. Cyan battery alpha bounds [1,1,15,15), centered (8,8), matching the retained 14x14 collision. `PlasmaCell` no longer references power_up.png; charge values and collection sound queue remain intact.
- Combined UI atlas described below supplies all sixteen icons, seven-slot cells, reusable card states and the shared XP bar. Foundation definitions reference their icon regions; later offensive icons remain presentation-only. No missile/drone/satellite/proc effect is enabled by producing its icon.
- First playable visibility revision: XP orbs use a scene-shared radial gradient texture and additive material behind their gold/ivory cores. The gradient fades from ivory through gold to transparent amber; projectile glow resources remain unchanged. Ordinary/high-value halos span 28/36 native pixels, pulse over 1.2 seconds and reset on pool reuse; merged values update the halo size. The authored sprite pair and 8 px collection distance are unchanged. The HUD retains the shared level and its progress bar using the atlas XP caps, without a numeric XP counter.
- `beam.png`, `plasma_beam_master.ase`, beam shader, widths/flow/tags and shield frame geometry are unchanged. Native captures verify manual normal/full-reserve overdrive distinction. The new shield charge cap is three; charge-window consumption is retained.

Fresh Aseprite exports for all four new/refreshed foundation pairs match runtime pixels, and all authored PNG colors belong to Lost Warden 64. The native foundation collision subset passes; inspection of actual solo/co-op/wide HUD, choices, maximum ranks, normal/overdrive beam and low/high XP vs plasma is recorded in phase_3_validation.md.

### Step 3 delivered UI mapping — 2026-10-20

The proposed separate icon/card/slot/bar masters above are consolidated into `assets/sources/ui/phase_3_upgrade_ui.aseprite` → `assets/sprites/ui/phase_3_upgrade_ui.png`. Both are **delivered**, 128x64, one RGB frame tagged `ui_atlas`, layer `Interface Geometry and Symbols`, using Lost Warden 64. All sixteen icon indices above occupy the first two 16x16 rows, including presentation-only future families. Row y32 holds six 16x16 nine-patch states (P1 idle/focus/ready, then P2), margins 4; x96/x112 hold offensive/utility empty cells. Row y48 holds empty/fill XP caps at x0/x8, each 8x4. A fresh Aseprite export is pixel-identical to the runtime PNG. Remaining proposed foundation/combat files stay pending.

The native selection uses the approved Arsenal layout: solo panel x16/y60/w608/h328, three cards x28/224/420, y130, 188x196; co-op panels x16/x326, y60, 298x328, with 274x66 cards at y130/204/278. Sixteen-pixel icons render at x2 scale in solo and x1 in co-op; seven slots and real text/rank labels remain UI nodes. Existing cannon/beam collisions are unchanged at this checkpoint.

See [selection_audio_brief.md](selection_audio_brief.md). No dedicated selection audio was found among supplied project assets. Existing menu cues are available for technical tests; their presence is not delivery of the requested musical moment. Sources/export destinations for future supplied files remain proposed until the actual files arrive.

## Verification boundary

### Current 64px Nomad effect compositions — 2026-10-20

The maintainer superseded the previous 32px symbols with a request for **64x64 sprites**, more representative of their effects, using the Nomad and actual shots, explicitly through the Aseprite MCP. The active card atlas is now `assets/sources/ui/upgrade_icons_64.aseprite` → `assets/sprites/ui/upgrade_icons_64.png`: 640x128, ten 64px columns: foundation order 0-7, then beam_capacity and beam_recharge at 8-9, P1 red in the first row and P2 blue in the second. One frame/tag `nomad_effect_icons` has four editable layers: `Field and Motion`, `Nomad Hull`, `Weapons and Pickups`, `Effect Highlights`.

The compositions reuse idle frame 0 from the actual `nomad-red.png`/`nomad-blue.png`, plus the live primary/side shot frames, XP diamonds and the full-size native reflector frame. The ship is copied at integer x2 (x1 in salvage), with independently authored effects around it, rather than replacing its silhouette with a generic fighter. Source gameplay assets are unchanged. Details:

| Family | Representation |
| --- | --- |
| speed | Nomad with extended paired exhaust and directional motion streaks |
| damage | Nomad firing one reinforced full-tier primary pulse |
| fire_rate | Nomad with three closely spaced primary pulses and cadence markers |
| orb_magnet | XP diamonds moving inward around the ship, with segmented attraction field |
| side_shot | Forward main shot plus the actual paired wing projectiles and muzzle points |
| energy | Green repair brackets, crosses and hull-restoration sparks around Nomad |
| shield | Actual native reflector above Nomad, supported by an arc and deflection sparks |
| score | Nomad collecting salvage from riveted ship plates and metal fragments |
| beam_capacity | Native beam emission beside an expanded segmented plasma bank |
| beam_recharge | Two native plasma cartridges feeding charge into the ship |

Cards display the new atlas at native 64x64 in both modes. Co-op icons occupy x6/y1 inside each 274x66 card; text starts at x76 to retain separation. Solo retains its centered icon at x62/y12. Miniature build slots and HUD use `assets/sources/ui/upgrade_miniatures.aseprite` → `assets/sprites/ui/upgrade_miniatures.png`: ten 16px columns with personal red/blue rows (160x32), tag `upgrade_miniatures`, layer `Nomad Effect Miniatures`. Their compositions are matched to the 64px cards, with refined cadence pulses, side shots, exhaust and charge indicators for small-size readability. Definition icons address the first row; HUD/menu presentation selects the correct team row without mutating shared resources. The preceding 32px source/export remain as a superseded art iteration and are no longer consumed by selection cards.

Validation: all twenty full-size cells have transparent margins, binary alpha and **37 exact Lost Warden 64 colors**; miniature art has 36 exact palette colors; both ownership variants differ for every family. Fresh Aseprite export matches the runtime PNG. `test_upgrade_selection.gd` passes **48 native checks**, including 64px source/display dimensions, correct P1/P2 atlas row, nearest sampling and existing selection behavior. Actual solo/co-op/wide captures and `.godot/phase_3_icon_review/menu_icons_64_zoom.png` were inspected for effect identity and icon/text separation. The approved beam charge utilities are playable; later offensive families remain pending and gameplay collision footprints are unchanged.

### Native 32px menu equipment icons — 2026-10-20

The maintainer requested more detailed menu icons, a stronger match to the game's graphical identity, then explicitly selected **native 32x32 sprites**. `assets/sources/ui/upgrade_icons_32.aseprite` exports to `assets/sprites/ui/upgrade_icons_32.png`: a 256x32 atlas with eight 32x32 cells, stable foundation order 0-7, one frame/tag `foundation_menu_icons`, layer `Nomad Upgrade Hardware`, and the full Lost Warden 64 palette. Imagegen provided a mechanical equipment concept; the final icons were redrawn directly at 32px with stepped pixel shading, steel/bronze housings, small status lights and restrained energy accents. They are not downsampled detailed renders or enlarged 16px symbols.

The selection cards use this dedicated atlas at x2 in solo (64x64) and x1 in co-op (32x32), with nearest sampling. Solo names/ranks/effect lines move below the larger symbol; co-op text starts at x48 to clear its 32px icon. Personal slot miniatures and the live HUD retain the preceding 16px atlas; gameplay pickups keep their existing native footprints. Future-family symbols retain their previous atlas fallback until their feature is delivered.

All 23 opaque RGB colors are present in Lost Warden 64; alpha is binary and every icon fits its 32px cell. Fresh Aseprite export equality passes. `test_upgrade_selection.gd` passes **48 native checks**, including source-cell/display sizes and independent co-op behavior. `phase3_selection_solo.webp`, `phase3_selection_coop.webp` and `phase3_selection_solo_wide.webp` show the actual updated layouts. The equipment concept prompt is recorded in [menu_icon_art_brief.md](menu_icon_art_brief.md).

### First playable icon and plasma review — 2026-10-20

The maintainer requested clearer upgrade symbols, especially the reversed-looking side-shot symbol, and a matching review of beam recharge pickups, with strict palette compliance. All eight active foundation cells (indices 0-7) have been redrawn in the existing Aseprite master. Side shots now show an upward-facing steel ship and two separated forward bolts above its wings. Speed, cannon damage, fire cadence, XP attraction, repair, reflector and salvage use distinct silhouettes. Future-family icons, card states, slot cells and bar pixels (all rows y>=16) are byte-identical to the preceding playable atlas.

The plasma master/export now depicts a metallic cartridge with shoulder caps, side rails and an inset cyan chamber with an ivory energy zigzag. Its cell remains 16x16 and its visible bounds remain [1,1,15,15); charge amounts, sound, collision and scripts are unchanged. Existing source tags, layer names and all resource atlas mappings are retained.

Imagegen supplied visual references for the eight-symbol sheet and plasma cartridge; the final runtime art was adapted on the native pixel grid in Aseprite. Reference briefs: (1) eight distinct 16x16 upgrade silhouettes, most importantly an upward ship with two forward side bolts; (2) a 16x16 upright plasma cartridge with metal caps and cyan/ivory energy chamber. Final opaque RGB values are verified against `assets/palettes/lost_warden_64.gpl`, with binary alpha and no antialiasing. Fresh Aseprite exports match the runtime PNGs pixel-for-pixel.

Native review uses `phase3_playable_coop_choices.webp` and `phase3_playable_xp_and_plasma.webp`; an enlarged actual-pixel strip is available at `.godot/phase_3_icon_review/foundation_icons_and_plasma.png`. Native progression activation passes 76 checks and the focused foundation collision suite passes. No later offensive family is activated by this art revision.

The baseline inspection used scene/resource/script references, PNG dimensions/alpha bounds, Aseprite binary metadata and animation JSON. Steps 3-4 additionally verify real Godot screenshots, source/export parity, palette, collisions and interaction. Economy calibration, later offensive artwork, dedicated audio and listening acceptance remain pending. See [validation evidence](../../../../docs/phase_3_validation.md).
