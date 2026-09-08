# Sprite Production Inventory

Status: production brief for the visual production phase.  
Scope: replacement art only. Keep the existing scene paths, stable gameplay identifiers, pivots, animation names, frame counts, and collision shapes unless an explicit compatibility migration is approved.

This inventory follows the approved Lost Warden universe bible and the 24-color palette. It distinguishes assets that belong to the visual production phase from assets owned by later gameplay phases. Do not create the deferred assets as part of the current visual-only phase.

## Production Rules

- Build every standard combat frame on a 32 by 32 logical-pixel canvas. Godot displays these frames at four times their native size; export with nearest-neighbor scaling only.
- A sprite may occupy less than the full canvas, but retain transparent padding around it for its current pivot and animation footprint. Use a larger sheet only when the existing scene already requires it, such as the large asteroid or the carrier.
- Use only `Lost Warden 24` from `assets/palettes/lost_warden_24.gpl`. The itch.io page establishes the visual hierarchy: Void background, gunmetal structures, Warden red, ember/amber heat, and sparse Star White highlights.
- Normal sprites should use about six colors: one shadow, two body tones, one highlight, and at most two accents. Keep emissive colors under ten percent of a normal sprite.
- Use hard color transitions and deliberate pixel clusters. Do not use antialiasing, blur, smooth gradients, soft glow, or subpixel detail.
- Use the pixel grid, palette, maximum dimensions, pivots, frame layout, animation timing, outlines, materials, engine colors, and projectile rules defined by the production specification before exporting any PNG.
- Preserve the runtime PNG path shown below and keep its editable source file beside the other source files under `assets/sources/`.
- A source file and its exported PNG are one deliverable. Do not commit only one of them.
- Preserve the existing visible footprint and transparent padding until collisions have been checked in-game.
- Player art uses navy, cyan, warm white, and coral damage accents. Player two keeps the same silhouette and uses violet secondary lights.
- Obsidian Dominion art uses charcoal, dark violet, bone highlights, red targeting lights, and amber engines.
- Prioritize readable silhouettes at gameplay scale over decorative detail.

## Visual Production Phase: Required Runtime Replacements

| Asset ID | Current runtime PNG | Editable source to replace or create | Replacement | Required visual notes |
|---|---|---|---|---|
| `nomad_players` | `assets/sprites/player/x_wing.png` until integration | `assets/sources/player/ship_banking_master.aseprite` | Nomad fighter sheet for both players | Use the existing 13-frame master source with its fixed `(16, 16)` pivot. The neutral pose has symmetrical swept fins, and every right bank mirrors its matching left bank. Export the red and blue variants by toggling the documented team-color layers. |
| `nomad_reactor_1` | `assets/sprites/player/player1_particle.png` | `assets/sources/player/player_reactors_master.ase` (`Player Red`) | Player-one reactor particle | Red, short and crisp; supports current movement and weapon feedback. |
| `nomad_reactor_2` | `assets/sprites/player/player2_particle.png` | `assets/sources/player/player_reactors_master.ase` (`Player Blue`) | Player-two reactor particle | Same layout as player one with violet secondary light. |
| `player_energy_1` | `assets/ui/player1_energy.png` | `assets/sources/player/player_energy_master.ase` (`Player Red`) | Player-one gameplay energy icon | Small, high-contrast Nomad-derived icon readable in the HUD. |
| `player_energy_2` | `assets/ui/player2_energy.png` | `assets/sources/player/player_energy_master.ase` (`Player Blue`) | Player-two gameplay energy icon | Same silhouette and frame layout as player one, with the player-two color cue. |
| `pulse_shot_primary` | `assets/sprites/player/player_shot.png` | `assets/sources/player/pulse_shot_primary_master.ase` | Pulse-cannon projectile | Five compact power tiers with red and blue player rows, bright colored envelopes, and warm-white cores. |
| `pulse_shot_side` | `assets/sprites/player/player_side_shot.png` | `assets/sources/player/pulse_shot_side_master.ase` | Side-cannon projectile | Five rounded 4×8 power tiers with red and blue player rows, clipped corners, and a narrow luminous core. At full power, the two side bolts and the primary bolt form a compact three-lobed bouquet before the side trajectories spread apart. |
| `plasma_beam` | `assets/sprites/player/beam.png` | `assets/sources/player/plasma_beam_master.ase` | Continuous plasma beam | Five charge tiers, each with a four-frame 80 ms flow loop. Beam widths progress through 4, 6, 8, 12, and 16 pixels for both players. The later overdrive emphasis belongs to Phase 5. |
| `nomad_shield` | `assets/sprites/player/shield.png` | `assets/sources/player/nomad_shield_master.ase` | Directional Nomad shot reflector | 24-frame 6×4 sheet with six symmetric charge levels. The concave barrier receives enemy fire at its white center, while the reflection frames split the captured energy into an upward return path. Red and cyan edges match the player projectiles, with violet secondary light for player two. The 16×10 cell footprint preserves the scene's current alignment. |
| `razor_fighter` | `assets/sprites/enemies/tie_sheet.png` | `assets/sources/enemies/tie_sheet.ase` | Razor Fighter | 13-frame 32×32 sheet with a three-frame engine idle, hit and damaged states, and a seven-frame explosion. Compact split spearhead, one red cannon, and one hard rectangular amber engine block. No ball cockpit or solar-panel wings. |
| `talon_interceptor` | `assets/sprites/enemies/interceptor.png` | `assets/sources/enemies/interceptor.ase` | Talon Interceptor | 11-frame 32×32 sheet with a three-frame twin-engine idle, hit and damaged states, and a six-frame explosion. Narrow central spear, longer detached side blades, and a more aggressive forward profile than the Razor Fighter. |
| `razor_wing_drone` | `assets/sprites/enemies/drone.png` | `assets/sources/enemies/drone.ase` | Razor Wing drone | 11-frame 32×32 sheet with one flight frame, one hit frame, and a nine-frame timed explosion. Compact central pod, paired hooked blades, one red targeting light, and one short amber engine block keep the formation silhouette clearly lighter than the interceptor. |
| `siege_turret` | `assets/sprites/enemies/turret.png` | `assets/sources/enemies/turret.ase` | Siege Turret | 11-frame 32×32 sheet with idle, hit, and nine explosion frames. Broad armored wedge with bone support ribs, paired amber heat vents, sparse red targeting lights, and one keyed central aperture whose amber notch makes the firing direction readable during rotation. |
| `grave_carrier` | `assets/sprites/enemies/mother_ship.png` until integration | `assets/sources/enemies/grave_carrier_32x64.ase` | Grave Carrier | Eleven-frame 32×64 heavy carrier with an asymmetric hull, bone armor ribs, central engine trench, and uneven amber engine blocks. Port and starboard turrets use separate layers, destroyed-state references, and named Aseprite slices for later gameplay integration. |
| `asteroid_small` | `assets/sprites/enemies/asteroid_sheet.png` | `assets/sources/enemies/asteroid_sheet.ase` | Small asteroid sheet | 11-frame 32×32 sheet with three rotations, matching hit flashes, and a five-frame rubble burst. `Finished Variants` now selects the original-shape Dark Slate render, with restrained mineral accents and dimmer highlights. The Earth and platework variants and hidden construction layers remain available. |
| `asteroid_large` | `assets/sprites/enemies/big_asteroid_sheet.png` | `assets/sources/enemies/big_asteroid.ase` | Large asteroid sheet | 18-frame 9×2 sheet of 32×32 cells with four rotations, matching hit flashes, a six-frame breakup, and three trailing-rubble cells. `Finished Variants` now selects the original-shape Dark Slate render, with restrained mineral accents and dimmer highlights. The Earth and platework variants and hidden construction layers remain available. |
| `enemy_shot_fighter` | `assets/sprites/combat/enemy_shot_fighter_sheet.png` | `assets/sources/combat/enemy_shot_fighter.ase` | Razor Fighter projectile | Four-frame 32×32 flight loop with a compact ivory core, Warden-red body, dark crimson envelope, and a short flickering particle trail. |
| `enemy_shot_interceptor` | `assets/sprites/combat/enemy_shot_interceptor_sheet.png` | `assets/sources/combat/enemy_shot_interceptor.ase` | Talon Interceptor projectile | Four-frame 32×32 red lance with a narrow ivory core, pointed head, split trail, and a faster 70 ms pulse that remains distinct from the broader fighter shot. |
| `enemy_shot_interceptor_side` | `assets/sprites/combat/enemy_shot_interceptor_side_sheet.png` | `assets/sources/combat/enemy_shot_interceptor_side.ase` | Talon side projectile | Four-frame 32×32 red dart with a compact ivory core and two animated swept fins forming a recognizable Y silhouette when aligned to a side-volley trajectory. |
| `enemy_shot_turret` | `assets/sprites/combat/enemy_shot_turret_sheet.png` | `assets/sources/combat/enemy_shot_turret.ase` | Siege Turret projectile | Twelve-frame 32×32 amber siege charge: four-frame radial flight pulse, two-frame hit compression, and six-frame explosion with an expanding broken ring and dispersing fragments. |
| `space_background_far` | `assets/sprites/world/parallax/far_stars.png` | `assets/sources/world/space_background_parallax.ase` | Far parallax stars | Sparse low-contrast stars with partial transparency for the slowest parallax plane. |
| `space_background_nebula_blue` | `assets/sprites/world/parallax/nebula_blue_haze.png` | `assets/sources/world/space_background_parallax.ase` | Blue nebula haze | Broad tileable gunmetal-blue currents built on an 8 px logical pixel grid with restrained alpha and no hard contour effects. |
| `space_background_nebula_mauve` | `assets/sprites/world/parallax/nebula_mauve_haze.png` | `assets/sources/world/space_background_parallax.ase` | Mauve nebula haze | Independent translucent Warden-red currents built on an 8 px logical pixel grid for a separate parallax speed. The existing mauve filename and layer name remain stable. |
| `space_background_nebula_filaments` | `assets/sprites/world/parallax/nebula_filaments.png` | `assets/sources/world/space_background_parallax.ase` | Nebula filaments | Sparse broken blue and deep-red highlights with pixel-stepped edges and restrained alpha. |
| `space_background_planets` | `assets/sprites/world/parallax/distant_planets.png` | `assets/sources/world/space_background_parallax.ase` | Distant planets | Two ringed planets and two smaller bodies, shaded with the shared palette and partial transparency. |
| `space_background_mid` | `assets/sprites/world/parallax/mid_stars.png` | `assets/sources/world/space_background_parallax.ase` | Mid parallax stars | Medium-density ivory and amber stars positioned above the nebula planes. |
| `space_background_near` | `assets/sprites/world/parallax/near_stars.png` | `assets/sources/world/space_background_parallax.ase` | Near parallax stars | Sparse bright stars and occasional cross-shaped highlights for the fastest star plane. |
| `space_background_debris` | `assets/sprites/world/parallax/distant_debris.png` | `assets/sources/world/space_background_parallax.ase` | Distant debris | Sparse gunmetal fragments for subtle foreground motion without competing with combat sprites. |
| `space_background_ruins` | `assets/sprites/world/parallax/orbital_ruins.png` | `assets/sources/world/space_background_parallax.ase` | Orbital ruins | Subtle broken orbital structures and distant panels on an independent transparent parallax plane. |

## Phase 2 Visual Production — In Progress

| Asset ID | Runtime PNG | Editable source | Production state | Visual notes |
|---|---|---|---|---|
| `razor_fighter_elite` | `assets/sprites/enemies/razor_fighter_elite_sheet.png` | `assets/sources/enemies/razor_fighter_elite.ase` | First elite treatment complete | Retains the base 13-frame Razor Fighter layout. Separate layers add a pale-violet one-pixel outline, four-step restrained red aura pulse, altered armor pixels, and a hidden compact health-bar reference. Explosion frames remain unchanged. |
| `talon_interceptor_elite` | `assets/sprites/enemies/talon_interceptor_elite_sheet.png` | `assets/sources/enemies/talon_interceptor_elite.ase` | Elite treatment complete | Retains the base 11-frame layout. Pale-violet blade inlays and outline emphasize its long spear profile, while a restrained red aura pulses behind the five combat-state frames. Explosion frames remain unchanged. |
| `razor_wing_drone_elite` | `assets/sprites/enemies/razor_wing_drone_elite_sheet.png` | `assets/sources/enemies/razor_wing_drone_elite.ase` | Elite treatment complete | Retains the base 11-frame layout and compact silhouette. A short fragmented red aura, pale-violet hook accents, and a brighter central pod distinguish the elite without giving it the interceptor's visual weight. Runtime opacity modulation will pulse the single-frame idle aura. |
| `siege_turret_elite` | `assets/sprites/enemies/siege_turret_elite_sheet.png` | `assets/sources/enemies/siege_turret_elite.ase` | Elite treatment complete | Retains the base 11-frame layout. Pale-violet siege-plate accents frame the central firing aperture, with a compact fragmented red aura around the armored wedge. |
| `grave_carrier_elite` | `assets/sprites/enemies/grave_carrier_elite_32x64_sheet.png` | `assets/sources/enemies/grave_carrier_elite_32x64.ase` | Elite treatment complete | Uses the 11-frame 32×64 carrier master with independent destructible turret layers and anchors. Command plates, a pale-violet outline, and a restrained red aura identify the elite while keeping the original footprint. |
| `dread_ark` | `assets/sprites/bosses/dread_ark_128x96_sheet.png` | `assets/sources/bosses/dread_ark_128x96.ase` | Boss phase art complete | Twelve-frame 128×96 command carrier derived from the wide arcing silhouette used in the itch.io identity art. Three dorsal spines frame the central trench; separate side-bay layers visibly open for Phase 2, and the trench changes to white and magenta for Phase 3. Named slices preserve launch-bay, battery, and ship anchors. |
| `dread_ark_projectiles` | `assets/sprites/combat/dread_ark_projectiles_sheet.png` | `assets/sources/combat/dread_ark_projectiles.ase` | Boss projectiles and impacts complete | Eighteen 32×32 frames provide four-frame loops for the aimed red lance, heavy amber broadside shell, and magenta hunter orb, followed by two-frame impact bursts for each projectile family. |
| `dread_ark_beam` | `assets/sprites/combat/dread_ark_beam_sheet.png` | `assets/sources/combat/dread_ark_beam.ase` | Final-phase beam segment complete | Four-frame 32×64 flow loop with a warm-white core, magenta body, violet edge field, and sparse broken arcs. The segment can tile vertically without smoothing. |
| `dread_ark_explosion` | `assets/sprites/effects/dread_ark_explosion_sheet.png` | `assets/sources/effects/dread_ark_explosion.ase` | Boss destruction complete | Fourteen 128×96 frames sequence wing detonations, central-core rupture, a broken shockwave, and dispersing hull debris on independent layers. |

## Explicitly Deferred Assets

| Owning phase | Asset ID | Future asset | Visual direction |
|---|---|---|---|
| Phase 3 | `energy_shard` | Experience-orb sprite and high-value variant | Falling, collectible energy shard that remains distinct from plasma cells and enemy shots. |
| Phase 3 | `upgrade_icons` | Icons for speed, damage, fire rate, side shots, orb attraction, repair, shield, and salvage | Small, stable HUD/card icons; do not rely on display text for their meaning. |
| Phase 4 | `dive_hunter` | Dive Hunter sprite sheet and charge telegraph | Razor Wing family; folded outer blades open during the charge warning. |
| Phase 4 | `furnace_bomber` | Furnace Bomber sprite sheet, payload, and drop telegraph | Siege Choir family; wide hull, two visible payload bays, slow falling shell. |
| Phase 4 | `lance_sniper` | Lance Sniper sprite sheet, aimed shot, sight line, and retreat cue | Siege Choir family; narrow vertical spine and a clear magenta sight line. |
| Phase 5 | `impact_sparks` | Player and enemy impact particles | Small bounded bursts, colored by source and target. |
| Phase 5 | `explosion_bursts` | Enemy, hazard, and heavy-ship explosion effects | Layered colored pixel bursts; preserve gameplay visibility. |
| Phase 5 | `orb_feedback` | Orb trail and collection burst | Must make XP collection clear without being mistaken for plasma or pickups. |
| Phase 5 | `level_up_ring` | Level-up ring effect | Short, readable player-centered confirmation effect. |
| Phase 5 | `bonus_shaders` | Orb halo and selected-upgrade-card outline/pulse | GL Compatibility-safe CanvasItem shaders. |

## Generated 32-Pixel Reference Boards

These are visual references for manual Aseprite production. They are enlarged for inspection and are not runtime sprite sheets. Rebuild every final frame on the 32 by 32 logical-pixel canvas and index it to `Lost Warden 24` before export.

| Reference board | Covers |
|---|---|
| `assets/art/sprite_references/nomad_hud_reactor_32px_reference.png` | Player energy icons and reactor-particle direction |
| `assets/art/sprite_references/warden_weapons_32px_reference.png` | Primary shot, side shot, plasma beam, and shield direction |
| `assets/art/sprite_references/razor_fighter_32px_reference.png` | Razor Fighter |
| `assets/art/sprite_references/talon_interceptor_32px_reference.png` | Talon Interceptor |
| `assets/art/sprite_references/razor_wing_drone_32px_reference.png` | Razor Wing drone |
| `assets/art/sprite_references/siege_turret_32px_reference.png` | Siege Turret |
| `assets/art/sprite_references/grave_carrier_32px_reference.png` | Grave Carrier |
| `assets/art/sprite_references/asteroids_32px_reference.png` | Small and large asteroids |
| `assets/art/sprite_references/dominion_projectiles_32px_reference.png` | Fighter, interceptor, side, and turret enemy projectiles |
| `assets/art/sprite_references/space_tiles_32px_reference.png` | Near and far parallax-space tile direction |
| `assets/art/sprite_references/future/dive_hunter_32px_reference.png` | Future Dive Hunter inspiration |
| `assets/art/sprite_references/future/furnace_bomber_32px_reference.png` | Future Furnace Bomber inspiration |
| `assets/art/sprite_references/future/lance_sniper_32px_reference.png` | Future Lance Sniper inspiration |
| `assets/art/sprite_references/future/rewards_and_abilities_32px_reference.png` | Future XP, plasma, upgrade, and ability-icon inspiration |
| `assets/art/sprite_references/future/dread_ark_64x32_reference.png` | Future Dread Ark boss inspiration |
| `assets/art/sprite_references/future/dread_ark_attacks_reference.png` | Future Dread Ark attack-state inspiration |
| `assets/art/sprite_references/background_far_tiles_32px_reference.png` | Far-parallax space tile atlas |
| `assets/art/sprite_references/background_near_tiles_32px_reference.png` | Near-parallax space tile atlas |
| `assets/art/sprite_references/future/obstacle_course_tiles_32px_reference.png` | Modular Dominion obstacle-course tile inspiration |

## Exclusions

- The earlier temporary-pickup exclusion was superseded by the maintainer on 2026-09-08. `assets/sprites/pickups/power_up.png` now uses the dark-space eight-cell atlas, with source `assets/sources/pickups/power_up_master.ase`. Direct pickups remain temporary until Phase 3.
- The plasma cell has a distinct atlas cell; this art revision does not change its gameplay role or charge amount.
- Do not create art for permanent progression, unlockable ships, currencies, profiles, or a hangar. Those systems are outside this roadmap.

## Per-Asset Completion Check

- Editable source exists and is synchronized with the exported runtime PNG.
- Runtime path, animation names, frame count, pivot, and node references still load.
- Sprite remains readable in solo and co-op at gameplay scale.
- Collision shape is aligned and has not been resized for decoration.
- GL Compatibility presentation has no missing texture, animation, or shader error.

## Dark Space Benchmark Update — 2026-09-07

The maintainer accepted the first benchmark and authorized extending it to the remaining produced assets. All five enemy families now use darker armor and selective highlights. All elite sources use interrupted violet markings with their aura layers hidden; this supersedes the continuous outlines, aura pulses, and proposed idle-aura modulation in the production rows above. Dread Ark retains the accepted first-pass treatment. Runtime integration of these presentation choices remains in its owning gameplay phase. See `docs/dark_space_art_review.md` for measurements, comparisons, and validation limits.


### Remaining Production Set — Pass 02

- Talon, drone, turret, carrier, and their elites: source-layer retouches preserve attack cues, hit flashes, explosion cels, and anchors.
- Asteroids: Dark Slate is the active finished variant; ordinary-frame white seams and bright mineral flecks are reduced while rotations and sheet order remain unchanged.
- Nomad: selective rear-wing shading across every banking frame; red/blue team colors, forward highlights, pivots, GIF timing, and mirror symmetry remain intact.
- Energy icons: darker lower casings; player colors and luminous cores are unchanged.
- Siege charge: subdued outer armor; inner charge, core, impacts, and explosion frames remain intact.
- Boss beam: Deep Ion outer edge around the retained magenta field and warm-white core.
- Boss destruction: hull debris matches the darker armor; blasts and shockwave remain unchanged.
- All nine parallax exports: subdued planet rings, warmer sparse stars, darker ruins/debris, and low-alpha blue/red nebula layers.
- Primary/side player shots, player beam, shield, reactor particles, fighter/interceptor projectiles, and boss projectile families were reviewed and retained: their bright cores already provide the required contrast against dark hulls. Player color semantics are unchanged in this pass.
- Legacy replacement targets, store identity art, archived reference boards, excluded pickups, and deferred future assets are outside this propagation pass.

The synchronized deliverables are 16 updated production sources, 26 PNG exports, and two player GIFs, in addition to pass 01. Comparison artwork is stored separately with its own editable sources. Static inspection and file-level validation are complete; in-game solo/co-op, collision alignment, and full GL Compatibility validation still belong to integration.


## Replacement Readiness and Temporary Pickups — 2026-09-08

See `graphics_replacement_readiness.md` for the current coverage audit and integration checklist. The produced set supports starting integration, but the Nomad destruction sequence is still missing from the new player master. Enemy-projectile mapping, carrier modules, background assembly, and HUD scaling also require integration work.

The temporary pickup replacement is now implemented: eight 16×16 cells at 2× preserve the 32×32 displayed size. Six active direct-upgrade icons, the retained beam slot, and a dedicated plasma-cell icon use dark chamfered casings with pale glyphs and sparse amber, blue, green or cyan accents. Both scenes use eight horizontal frames; fire rate uses its own frame without runtime tinting. Godot headless mapping/collection checks passed. The prior pass-02 pickup exclusion is historical and no longer applies.


### Pickup Legibility Revision

After user feedback, the temporary pickup master now uses 16×16 cells, a 128×16 PNG atlas, and 2× scene scale. The previous 8×8 glyph treatment is superseded. Explicit boot, medical cross, shield, battery, and projectile motifs replace the abstract symbols. Both pickup scenes retain their 32×32 displayed size and unchanged collision shapes. This is an intentional local grid exception for small readable icons.

## Stronger Explosion Pass — 2026-09-08

This requested pass supersedes the earlier decision to preserve explosion pixels. Revised the explosion layers of all ten ordinary/elite enemy sources and their sheets, plus the Dread Ark destruction effect, retaining existing frame layouts and timings. Added `assets/sources/effects/nomad_explosion.ase` and `assets/sprites/effects/nomad_explosion_sheet.png`: nine 32×32 frames, 100 ms each, `explode` tag, separate fire and hull-fragment layers, transparent final frame. The Nomad effect is ready for scene integration. See `docs/graphics_replacement_readiness.md` for validation and remaining integration work.

## Gameplay Test Library — 2026-09-08

Added 26 reusable effect variants, 12 industrial wreckage modules inspired by the local itch.io background, and three enemy art prototypes (Furnace Bomber, Lance Sniper, Dive Hunter). This is preparation-only asset production, not implementation of their roadmap gameplay roles. Native sources, transparent PNG sheets, previews and machine-readable catalogs are available. See `docs/gameplay_test_sprite_library.md` for layouts, timing, anchors and validation. All 30 native source files were re-rendered and checked pixel-for-pixel against their exported sheets; catalog frame timing also passed.
