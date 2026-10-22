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

### Step 7 — piercing and critical art — 2026-10-20

Produced through the Aseprite MCP and consumed by the completed piercing/critical families. These delivered mappings supersede the earlier proposed effect paths and atlas sizes. Full [runtime and visual evidence](validation/step_7_piercing_criticals.md) accompanies the code.

| Editable source | Runtime export / explicit mapping | Pivot, visible footprint and collision |
| --- | --- | --- |
| `assets/sources/player/weapons/piercing_shot.aseprite` | `assets/sprites/player/weapons/piercing_shot_sheet.png` + `.json`; five 16x16 source frames, horizontal 80x16 export. Tags `small`, `normal`, `big`, `large`, `full` map to columns 0-4. P1/P2 occupy y0-7 / y8-15; runtime 16x8 cells, existing frame 0-4 / 5-9. Assigned by `player_shot.tscn`'s `piercing_texture`. | Cell center (8,4), existing sprite offset. Every alpha byte matches the base primary atlas, including all tier footprints; original animated collision tracks unchanged. Segmented ivory core retains red/blue edges. |
| `assets/sources/player/weapons/piercing_side_shot.aseprite` | `assets/sprites/player/weapons/piercing_side_shot_sheet.png` + `.json`; five 6x16 source frames, 30x16 export, same five tags. Runtime 6x8 cells, same owner rows and tier frames. Assigned explicitly by `player_side_shot.tscn`. | Cell center (3,4), existing sprite offset. Every alpha byte matches the base side atlas; no collision enlargement. Existing side-rank tier mapping remains 0/1/2/4. |
| `assets/sources/effects/critical_impact.aseprite` | `assets/sprites/effects/critical_impact_sheet.png` + `.json`; six 24x48 source frames, 144x48 sheet. Tag `critical_impact`, frames 0-5, 50 ms each. Runtime 24x24 cells; P1/P2 use frame 0-5 / 6-11, owner rows y0-23 / y24-47. | Center (12,12), explicit owner slice pivots. Maintainer-approved stronger ivory star followed by red/blue fracture rays; 300 ms total, 32 simultaneous effects maximum. Sprite2D only, no collision. |
| `assets/sources/ui/upgrade_icons_64.aseprite` | Existing atlas expanded to `assets/sprites/ui/upgrade_icons_64.png`, **768x128**. Existing columns 0-9 preserved; piercing is column 10 (x640), critical_hits column 11 (x704). Native 64px owner rows y0/y64; tag `nomad_effect_icons`, one frame. New editable layer `Piercing and critical effect compositions`. | Native 64x64 cards in both layouts. Actual Nomad hull, two perforated plates and a traveling bolt for piercing; focused star above the hull for criticals. Transparent margins, no collision. |
| `assets/sources/ui/upgrade_miniatures.aseprite` | Expanded `assets/sprites/ui/upgrade_miniatures.png`, **192x32**, tag `upgrade_miniatures`. Columns 10/11 at x160/x176; P1/P2 rows y0/y16. Definition icons address the P1 row; existing HUD/selection code derives P2 without mutating the resources. | Native 16x16 silhouettes match the large compositions and fit the existing seven-slot cells. No collision. |

The Aseprite API composites and compares every source frame against its export: exact equality for all five pairs, binary alpha, exact Lost Warden 64 colors. Original primary/side masters and exports, beam assets and all animated projectile collision geometry remain unchanged. The additional piercing textures are selected only on compatible ranked gun emissions and restored on pool reuse. Native solo/co-op cards, personal HUD miniatures and four critical animation samples were inspected; focused pixel/effect receptors score 2/2 as recorded in the evidence. No `animation_rework` sheet is activated.

The maintainer's readability follow-up expands only the critical source/export from 16px/240ms to the 24px/300ms mapping above. Fresh Aseprite verification reports exact source/export pixels, binary alpha, six 50ms durations and 482 opaque palette pixels. `critical_hud_{0,1,3,5}.webp` captures the stronger owner variants at native 640x400 alongside the new elimination HUD; no gameplay damage footprint is changed. Enemy and surviving boss-cannon flashes also hold longer on an accepted critical hit.

### Signature beam piercing revision — 2026-10-21

This revision supersedes the live cannon-piercing mapping above. Through the Aseprite MCP, column 10 now depicts a continuous plasma beam with 8/6/4 px stepped sections, two pierced plates, the actual Nomad and a cyan plasma cartridge. Large cards retain x640 64px cells and y0/y64 owner rows in the 768x128 atlas; matched 16px miniatures retain x160 and y0/y16 in the 192x32 atlas. The new editable layer is `Piercing signature plasma beam`. `beam_piercing.tres`, HUD snapshots and selection artwork reference these cells. Columns 0-9 and 11 remain pixel-identical to the preceding exports.

Fresh source composites match runtime exports exactly, with binary alpha and exact Lost Warden 64 colors. Original beam art/shader are reused by progressively narrower runtime segments. Historical gun-piercing sheets remain for legacy fixtures but are no longer selected by a live upgrade offer. Native normal/overdrive sequences and updated cards show both owners. See [beam runtime/art evidence](validation/beam_piercing.md).

### Electric cannon chains — 2026-10-21

Delivered ahead of missiles at the maintainer's request. `assets/sources/combat/energy_chain.aseprite` exports `assets/sprites/combat/energy_chain.png` plus `.json`: four 48x32 source frames, tag `energy_arc`, 60 ms each, horizontal 192x32 sheet. Per frame, red/blue owners occupy y0-15/y16-31; the 32x8 link tile starts at x0, and the 16x16 anchor at x32 has pivot (8,8). Finite runtime links follow the accepted enemies through weak references and local impact offsets, with an owner rim/ivory core and animated tile/anchor accents; 240 ms total, sixteen global instances, no collision or owning target references. A removed enemy leaves its endpoint at the last known position. No sprite export changes are needed for this movement follow-up.

Card and miniature atlases append column 12 without changing columns 0-11. Cards now measure 832x128, with x768 cells and y0/y64 team rows. Miniatures measure 208x32, with x192 cells and y0/y16 rows. Both editable masters add `Nearest target electric arcs`; the illustration uses the actual Nomad and branching lightning between distinct targets. Source/export equality, binary alpha, preserved prior columns and exact Lost Warden 64 colors pass for all three asset pairs. The chain sheet contains 780 opaque pixels. Native solo/co-op/boss and choice captures are reviewed in [chain evidence](validation/energy_chains.md).

### Step 8 — guided micro-missiles — 2026-10-21

Produced through the Aseprite MCP. `assets/sources/player/weapons/micro_missile.aseprite` exports `assets/sprites/player/weapons/micro_missile_sheet.png` plus `.json`, eight 16x48 frames arranged horizontally as 128x48. Per-frame owner rows y0-23/y24-47 become 16x24 runtime cells. Tags: `guided_flight`, frames 0-3 at 60 ms; `contact_impact`, frames 4-7 at 50 ms. Both owner slice pivots are (8,12). The steel guided hull, team accents, fins and propulsion use frames 0-3/8-11; finite impacts use 4-7/12-15, 200 ms, at most 24 instances. Central hull collision is 5x10 at (0,-3); fins/exhaust are decorative, and impact sprites have no collider.

Menu/HUD masters append column 13 in layer `Autonomous guided micro missiles`, preserving all prior pixels. Card export is 896x128 with x832 64px cells and y0/y64 team rows. Miniature export is 224x32 with x208 16px cells and y0/y16 rows. The illustration combines the real Nomad with the new guided projectiles. Fresh composite/export parity, exact Lost Warden 64 colors, binary alpha, frame timings and prior-column identity pass for all three source/export pairs; the projectile sheet contains 804 opaque pixels. Actual solo/co-op flight, physical impact and card captures are inspected in [missile evidence](validation/micro_missiles.md).

### Missile size/count playtest revision — 2026-10-21

The preceding missile mapping is superseded by sixteen 16x48 source frames, exporting 256x48. Tags `flight_small`, `flight_medium`, `flight_large` use frames 0-3/4-7/8-11 at 60 ms; `contact_impact` uses 12-15 at 50 ms. P2 runtime frames add 16; owner cells/pivots stay 16x24/(8,12). All four prior impact frames remain pixel-identical after remapping. Native redrawn hulls use 3x6 / 4x8 / 5x10 central collisions at (0,-1)/(0,-2)/(0,-3), with independent shapes per missile and 1/2/3-projectile volleys. No fractional sprite scaling is used.

Column 13 of the existing 896x128 card and 224x32 miniature atlases now depicts the three graded sizes, in layer `Ranked missile volleys`; all prior columns are unchanged. Exact source/export equality, Lost Warden 64 colors and binary alpha pass, with 1,172 opaque projectile pixels. Native rank-1/rank-3, co-op flight and updated cards were reviewed. See [current missile evidence](validation/micro_missiles.md).

The baseline inspection used scene/resource/script references, PNG dimensions/alpha bounds, Aseprite binary metadata and animation JSON. Delivered checkpoints additionally verify real Godot screenshots, source/export parity, palette, collisions and interaction. Human economy acceptance, steps 13-14 artwork, dedicated audio and listening acceptance remain pending. See [validation evidence](../../../../docs/phase_3_validation.md).

### Escort drones, banking and matched reactors — 2026-10-21

- `assets/sources/player/weapons/escort_drone.aseprite`: six 24x144 frames, exporting `assets/sprites/player/weapons/escort_drone_sheet.png` (144x144) with JSON. Each runtime cell is 24x24, pivot (12,12). Rows are P1 idle / left / right, then P2 idle / left / right. Runtime frame is `(team * 3 + bank) * 6 + animation_frame`. Tags `hover` 0-3 at 80 ms and `fire` 4-5 at 50 ms. Layers separate banked steel/team hulls from muzzle flashes; no baked flame remains.
- Two small reactor mounts at x +/-3.5, y5 use reduced copies of Nomad's core/ember particle effect at scale 0.45. Each copy has 4 core / 7 ember particles and shares the owner's current amount, speed, length and brightness response; P2 retains its existing blue gradients. Maximum additional particles for four escorts is 88. Hull sprites and the entire support remain non-blocking.
- `assets/sources/player/weapons/drone_bolt.aseprite`: four 8x32 frames, exporting the 32x32 PNG/JSON pair. Owner cells are 8x16, pivot (4,8), red then blue rows; `flight` frames 0-3 at 60 ms. The 3x8 central collider follows a straight emission vector; generic finite contact feedback is reused.
- Menu and miniature masters append column 14, layer `Nomad and aimed escort`. Exports are 960x128 / 240x32, with x896 / x224 owner cells and y0/64 / y0/16 team rows. The composition shows Nomad and the rank-three pair; all older columns remain pixel-identical.
- Palette, source/export parity, native solo/co-op/wide, both banks, matched reactor states and edge presentation are recorded in [escort evidence](validation/escort_drone.md). Dedicated audio remains pending from the maintainer.

### Orbiting contact satellites — 2026-10-21

- `assets/sources/player/weapons/orbiting_satellites.aseprite`: eight 16x32 frames; matching PNG/JSON export `assets/sprites/player/weapons/orbiting_satellites_sheet` is 128x32. Runtime cells are 16x16, pivot (8,8). Row 0 is P1 and row 1 is P2: one canonical orientation each, with continuous scripted Sprite2D rotation. `orbit` frames 0-3 use 80ms, `contact` frames 4-7 use 50ms. Runtime frame is `team * 8 + animation_frame`. The radius-four collider does not rotate.
- Beveled steel cores retain the radius-four contact circle. Four thin tapered spikes and finite contact sparks are decorative. The master separates steel hulls, asymmetric team inserts and accepted-contact glints into three editable layers. The owner-attached controller maintains exact 32px geometry; no interpolation or scale enlarges the collision footprint, and no bullet-interception layer is present.
- Menu/miniature masters append column 15 in layer `Three contact orbiters around Nomad`. Exports are 1024x128 / 256x32 with x960 / x240 cells, and separate y0/64 / y0/16 team rows. Earlier fifteen columns remain identical to the published escort checkpoint. Long co-op card titles fit without colliding with rank text.
- All three source/runtime pairs are pixel-identical, palette-exact Lost Warden 64 and binary alpha. Real Razor Wing proximity contacts, team colors, eight-way pixel orientation and native/wide/edge states are reviewed in [satellite evidence](validation/orbiting_satellites.md). No audio was added.

### Impact explosions — 2026-10-21

- `assets/sources/combat/impact_explosion.aseprite`: eight 64x384 frames at 40ms, tag `detonate` 0-7. Export `assets/sprites/combat/impact_explosion.png` is 512x384 with matching JSON; runtime cells are 64x64, centered pivot (32,32). Rows 0-2 are P1 ranks 1-3; rows 3-5 are P2 ranks 1-3. Runtime frame is `(team * 3 + rank - 1) * 8 + animation_frame`.
- The sequence has a small ignition flash, expanding lobed fire front, hollowing blast and cooling fragments. Authored rank radii are 20/26/32px with no sprite scaling. The bright area stays within each damage radius; the animation itself has no collider and performs no damage. Lifetime is 320ms, with at most eight simultaneous visual instances.
- Menu/miniature masters append column 16, layer `Nomad explosive impacts`, with real Nomad and an outgoing shot below the blast. Exports are 1088x128 / 272x32; owner cells start at x1024 / x256 and y0/64 / y0/16. All preceding visible pixels, including the incoming satellite column, are preserved; the first fifteen columns remain byte-identical to the published checkpoint.
- Aseprite MCP authoring and fresh source/export composite audits report zero differing visible pixels for all three pairs. All opaque pixels match Lost Warden 64 exactly, with binary alpha. Solo/co-op/wide sequence and menu captures are reviewed in [explosion evidence](validation/impact_explosions.md). No new audio was supplied or generated.

### Expanded explosion footprint — 2026-10-22

Supersedes the preceding explosion grid: eight **96x576** source frames export **768x576** with six 96x96 runtime rows. Pivots are (48,48); P1 ranks occupy rows 0-2, P2 ranks rows 3-5. The same `detonate` 0-7 tag and 40ms timing remain. Native art is rebaked through Aseprite MCP to match radius **32/40/48px** without runtime sprite scaling; source/export audit reports zero differing visible pixels. Palette-exact Lost Warden 64 and binary alpha pass. The existing card/miniature columns are unchanged. Updated solo/co-op/wide screenshots show the larger footprint and percentage card text; no new audio is included.

### Concentrated explosion footprint — 2026-10-22

The final maintainer tuning reduces each 32/40/48px radius by one quarter to 24/30/36px. The source is rebaked through Aseprite MCP from the original editable animation, retaining the 96x96 native cells, (48,48) pivot, six owner/rank rows, 768x576 export and eight 40ms frames. No runtime scaling is used. Source/export visible pixels match exactly; palette and binary alpha pass. Refreshed solo/co-op/wide captures show the smaller blasts and doubled 70/90/110% damage values; card/miniature art remains unchanged.

### Synchronized expanding wave — 2026-10-22

The approved correction replaces the previous blast drawing with two editable Aseprite MCP layers: `Active expanding front` and `Inactive cooling fragments`. Source/export retain eight 96x576 frames / 768x576 sheet, six 96x96 owner/rank cells, pivot (48,48), Lost Warden 64 and binary alpha. `detonate` is 0-7, `active_wave` is 0-3, `cooling_fragments` is 4-7, all at 40ms. Active keyframes match radius fractions 25/50/75/100%; frames from 160ms use sparse dim clusters, without a bright damage-looking ring. The combat service supplies the elapsed time; visuals have no independent process clock or hit logic. Gameplay continues even when visual capacity is saturated.

Fresh composite/export audit has zero differing visible pixels; palette/alpha/tag mapping pass. Native `explosion_wave_*` sequences show actual victims and local hit flashes in solo/co-op/wide, followed by the inactive tail. Cards say AREA and percentage bonuses, with no target-count claim. Existing icons/miniatures and audio remain unchanged. See [wave evidence](validation/impact_explosion_wave.md).

### Steel satellite art and motion revision — 2026-10-22

The maintainer requested metallic spiked satellites, faster orbits and independent body spin, then rejected the first flat cross-like draft. The replacement was authored and exported through the Aseprite MCP: native 16x16 cells, 128x256 sheet, unchanged `orbit`/`contact` frame timings and team rows. Layers are `Beveled steel core and four tapered spikes`, `Asymmetric player color inserts` and `Accepted contact glints and sparks`. The body has shaded metal bevels, needle tips and an asymmetric insert/rivet to reveal rotation; no runtime sprite rotation or scaling is used. The 1.25-second orbit and 0.625-second spin share the physics clock.

The existing satellite column 15 is redrawn in both UI masters: three steel orbiters around actual Nomad art in the 64px card, one recognizable steel orbiter in the 16px miniature. Current full atlases remain 1088x128 and 272x32 after the explosion column. Every pixel outside satellite column 15 is identical to the incoming working tree. Source/export visible parity, exact Lost Warden 64 palette, binary alpha, eight distinct directions and animation metadata pass. No audio is added.

### Scripted satellite rotation supersedes baked directions — 2026-10-22

At the maintainer's request, Aseprite now retains only the canonical red and blue hulls from the refined art above. The source/export mapping at the start of the satellite entry is current: 16x32 source frames, 128x32 export, one orientation per team plus the retained eight-frame reflection/contact animation. The three editable layers and both UI illustrations are preserved. `Sprite2D.rotation` provides the continuous body spin independently of the unrotated collision circle; the earlier eight-direction atlas is superseded. Pixel identity of both retained hull rows is verified against the preceding source composite.

### Satellite selection illustration follow-up — 2026-10-22

The maintainer requested updating the satellite selection illustration after scripted rotation replaced baked directions. The Aseprite MCP redraws only column 15 of `upgrade_icons_64.aseprite` and its PNG export. Both team cards now feature the exact canonical gameplay hull enlarged by integer pixels in the foreground, with the real Nomad, two smaller rotated satellites and restrained orbital/spin marks. This improves identification at the existing 64px card size. All other columns and the miniature atlas are unchanged. Source/export parity, exact palette/binary alpha and native solo/co-op selection inspection pass; the selection regression passes all 48 checks.

### Selection foreground size adjustment — 2026-10-22

The maintainer found the foreground satellite too large. The Aseprite card now uses the canonical 16px hull at native size, matching the other two satellites, instead of the previous 32px enlargement. Its small rotation mark is resized accordingly; both team colors are updated. Source/export parity, exact palette/binary alpha and preservation of every other atlas column pass. This supersedes the larger foreground composition above.

### Defensive survival pack — 2026-10-22

The Aseprite MCP creates `assets/sources/player/reflector_sphere.aseprite` (eight 48x96 source frames, native 48px cells, two player rows) and `assets/sources/player/weapons/retaliation_pulse.aseprite` (eight 128x768 frames, six team/rank rows). Matching PNG/JSON exports are 384x96 and 1024x768. Sphere tags: idle 0-3, impact 4-5, rupture 6, return 7. Pulse tags: active_wave 0-3 and cooling_fragments 4-7, all 40ms. Gameplay and pulse presentation share the physical age.

The two UI masters now have 19 columns (1216x128 cards, 304x32 miniatures), layer `Defensive survival builds`. Shield replaces column 6; armor and retaliation use columns 17/18. The canonical Nomad and player palette remain. All other incoming columns, including the latest reduced satellite foreground, are pixel-identical. Four source/export pairs, palette/binary alpha and native solo/co-op/wide states pass. Existing reflector sound is retained; optional rupture/return nodes await supplied audio. See [defensive validation](../2026_10_22_defensive_pack/validation.md).
