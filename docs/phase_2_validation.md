# Phase 2 validation

## Step 2 — Continuous encounters (2026-10-17)

Implemented on `codex/phase-2-encounter-director`, following maintainer authorization for step 2 only.

### Runtime behavior

- Retain all 18 composition resources and their allowed lanes, movement profiles, spacing, and gap-wall openings. Add an explicit V formation to the opening fighter composition. Encounters now last 20, 25, or 30 seconds and chain immediately, without the former two-second transition or final-wave loop.
- Generate an internal seed on run reset. Encounter selection, formations, and enemy initialization use their dedicated streams. Cosmetic randomness cannot alter those choices. Current direct pickups use the drop and upgrade streams until Phase 3 replaces their mechanics. Debris positions derive from their source enemy seed.
- Start each encounter with `threat_budget * danger`, with a base budget of 30 and a 1.2 co-op budget multiplier. Spend the budget on weighted formations and pace the next formation by its cost divided by the encounter budget rate. Unspent capacity at the active cap never produces a catch-up burst.
- Each enemy family declares its stable identifier, threat cost, danger range, selection weight and linear weight growth. Interceptors unlock at danger 1.4, turrets at 1.8, and carriers at 2.4. All encounter compositions are eligible by danger 3.34, before eight minutes. Common families remain eligible throughout.
- Apply the director's capped health, movement, and fire-delay scaling. Preserve the existing co-op health multipliers and fractional damage. Asteroids receive no danger or co-op stat scaling. Mounted turret health and fire cadence inherit the hull modifiers once.
- Cap all active enemy collision bodies and reserved deferred spawns at 70 solo / 90 co-op. A carrier reserves three slots for its hull and two turrets. Its family limit of three prevents spawning into occupied anchors. Asteroid debris uses the same reservation accounting.
- Advance encounter and formation timing in one physics update, using deferred materialization. Pause stops that update. Stopping the run rejects queued spawns; run-level co-op settings survive a partner's death.

### Transitional compatibility

- Backgrounds still receive `wave_changed` with the encounter count. The maintainer-requested HUD follow-up replaces the visible wave count with survival time; danger remains internal.
- F1/F2 now adjust danger by -0.2/+0.2 through the retained debug method names, because sequential wave navigation no longer exists. F3–F6 remain intact.
- Maintainer-requested debug follow-up: **N** uses the existing `debug_next_wave` input action to skip directly to the next eligible encounter. The skip cancels pending spawns from the previous encounter while preserving enemies already in play. It does not advance survival time, boss scheduling time, or danger; pause, boss, recovery, and stopped-run states block the skip. It is available only while `global.Debug` is enabled.
- Score saving continues. Freeze legacy `bestWave` values so encounter counts cannot overwrite them; the subsequent maintainer-requested records follow-up adds independent solo/co-op `bestTime` values.
- Elite promotion, elite art integration, actual boss encounters, and the boss HUD remain steps 3–5. The regular run continues after five minutes at this checkpoint.

### Verification

Godot 4.7.2, using an ignored isolated project in `.godot/phase_2_runtime_validation/` with the current source/assets, existing import cache, and separate temporary save directories. This excludes the ignored root override's missing local Godot AI helper and does not use personal saves.

| Check | Result |
| --- | --- |
| `tests/test_encounter_director.gd` | PASS — 859 checks |
| `tests/test_encounter_spawning.gd` | PASS — 6,004 checks, including the maintainer-requested debug skip and its input/state guards |
| `tests/test_alpha_9_balance.gd` | PASS — 161 checks; obsolete wave/endless assertions migrated to director scaling, while upgrade, damage, health, pickup, and projectile-pool regressions remain |
| `tests/test_wave_progression.gd` | PASS — 638 checks; seeded encounters, debug offsets, survival HUD, solo/co-op duration records, game-over/hiscore screens, and legacy save preservation |
| `tests/player/test_fire_input.gd` | PASS |
| `tests/player/test_beam_effect.gd` | PASS |
| `tests/test_native_scale.gd` | PASS |
| `tests/test_enemy_feedback.gd` | FAIL — the same 34 animation-frame assertions already recorded in `docs/phase_1_playtest.md`; affected animation scenes/tracks are unchanged |
| Main scene, 120 headless frames | Starts and exits; the previously recorded four ObjectDB instances / two resource references remain at shutdown |
| Native Compatibility co-op preview | Runs and captures gameplay without runtime errors; player firing, encounter spawning, bounds, and existing HUD visually inspected |
| `git diff --check` | PASS |

The spawning suite materializes real enemy scenes with scripted lifetimes. It compares families, positions, movement seeds and health for equal/different seeds, injects unrelated random draws, checks seamless transitions, samples early/late family frequency, and exercises formations, pending reservations, debris, mounted inheritance, stop behavior and co-op limits. It freezes enemy motion and attack timers during those simulations; it is not a complete human gameplay or performance test.

The progression suite additionally reports two MP3 playback/resource instances at shutdown (`Retro-Futurist Drive.mp3`), consistent with the existing audio shutdown issue. Its assertions pass. No animation or audio repair is included in this step.

The temporary step 2 co-op capture is `.godot/phase_2_runtime_validation/phase_2_coop_preview.png`. The full phase still requires elite/boss integration, complete runtime validation, and solo/co-op readability and balance playtests. No commit or publication was performed.

## Survival HUD follow-up (2026-10-17)

The maintainer requested the survival HUD before elite and boss integration, then explicitly removed danger from the intended player presentation.

- Display `SURVIVAL` and elapsed `mm:ss` in the existing right HUD rail. Keep the current node path for compatibility; the node no longer displays encounter counts.
- The director publishes elapsed survival time through `Events.run_time_changed`; the HUD never reads the spawner or player nodes.
- Display completed seconds, with total minutes continuing beyond one hour. Start each run at zero, freeze time during pause or after run stop, and continue counting during future boss encounters.
- N changes encounters without adding survival time. F1/F2 still adjust internal danger, which is not displayed in the player HUD.
- Keep score-saving and legacy record behavior intact. Game-over/record-screen migration and `bestTime` were subsequently authorized and implemented in the follow-up below.

Validation: progression and HUD suite **606 checks, 0 failures** in solo/co-op, plus native-scale regression PASS. The existing MP3 shutdown warning remains as recorded above. Native Compatibility solo/co-op previews are stored locally as `.godot/phase_2_runtime_validation/survival_hud_solo.png` and `survival_hud_coop.png`.

## Survival records and results screens (2026-10-17)

The maintainer requested adapting the hiscore and game-over screens to the new survival presentation.

- Game over displays the final survival duration and best survival alongside the current score and hiscore. The records screen shows independent best score and best survival for solo and co-op. Neither screen displays wave counts or danger.
- Add integer `bestTime` fields to each mode, storing completed seconds. Existing saves receive zero by the existing defaults merge; preserve all legacy scores, `bestWave` values and saved preferences without inferring a duration from a wave record.
- Publish the director's final elapsed-time snapshot to `global.survival_time` before notifying the HUD. Reset current time at the start of each new run while preserving saved records. Use the same time formatter for the HUD, results, and records screens, including runs longer than one hour.
- Save a new duration record independently of score improvements and preserve the other mode's records.

Validation: **638 checks, 0 failures** in `tests/test_wave_progression.gd`, including legacy load/save round trips, independent mode records, shorter runs, longer low-score runs, live timer snapshots, results text, hiscore card values, and Start navigation. Native-scale and screen-transition regressions PASS. The existing two-instance MP3 shutdown warning remains in the headless progression/transition suites; the native previews complete without runtime errors.

Compatibility-renderer captures were visually inspected: `.godot/phase_2_runtime_validation/game_over_survival_solo.png`, `game_over_survival_coop.png`, and `hiscores_survival.png`. Source scene node paths are preserved for compatibility. Boss health and full-phase validation are still pending; this delivery does not start elite or boss implementation.

## Step 3 — Deterministic elites (2026-10-17)

Implemented after the maintainer requested committing the survival/debug checkpoint and proceeding to the next roadmap step. Boss combat and XP remain outside this step.

- Promote eligible formation members through the seeded enemy stream using the existing elapsed-time curve: zero before two minutes, 5% at three minutes, 10% at five, 18% at eight and at most 25% from twelve minutes. Stop promotion after the first successful member in each formation.
- Reserve elite capacity together with deferred body slots. At most three living/reserved elites exist in either mode; stop, debug skip and invalidated materialization release their reservations. Hazards, mounted turrets and secondary debris never promote.
- Apply 2.5x health, 1.1x movement, 0.8x fire delay and 3x score, stacking once with existing director, rule and co-op modifiers. Mounted modules inherit hull durability/cadence once and do not become separate elites. Retain guaranteed power-up plus large plasma rewards until Phase 3 introduces XP.
- Use existing approved elite textures for drones, fighters, interceptors, standalone turrets and carriers. Configure atlas grids in enemy data; the carrier uses an atlas region for its hull. Keep collision geometry and source palette unchanged. Remove the previous full-sprite tint, continuous outline and red aura. Render only a compact fractional-health bar above the sprite and hide it upon destruction.
- Report actual elite counts, queued slots and promotion chance in the full debug inspector and existing spawn journal.

Validation: `tests/test_elites.gd` **3,268 checks PASS**, covering repeated seeded traces and unrelated RNG noise, pre-two-minute exclusion, the capped chance, per-formation and solo/co-op limits, live/deferred cancellation, every family, stat stacking, mounted inheritance, fractional bars, collision preservation and guaranteed rewards. Director **859**, encounter spawning **6,004**, progression **638**, Alpha 9 combat **161** and debug **66** checks PASS. Fire input, plasma beam and screen fades PASS.

Native Compatibility solo/co-op presentation captures were visually inspected with normal/elite pairs and partially depleted bars: `.godot/phase_2_runtime_validation/elite_solo.webp` and `elite_coop.webp`. These staged comparisons verify five family appearances and contain three elites each; they are not a density/performance playtest. No raster sources or animation tracks were edited.

Known pre-existing limits remain: the feedback suite reports 34 invalid-frame assertions on carrier/mounted-turret animation checks, with additional intermittent wall-clock hit-flash assertions in headless runs; some audio-owning suites retain MP3 resources at shutdown. These are tracked separately from elite integration. Complete-phase boss and human balance validation remain pending.

### Elite balance follow-up (2026-10-17)

The maintainer requested tougher, more dangerous elites after observing them in gameplay. Raise elite health from 2.5x to 3.0x (+20%) and reduce firing-delay scaling from 0.8x to 0.7x (about 14% more frequent attacks). Keep movement, promotion rates, the three-elite cap, score and rewards unchanged. All five ship families share this resource; mounted carrier modules inherit the new hull health/cadence once. The existing elite and Alpha 9 regression assertions use the revised values.

## Step 4 — Dread Ark boss runtime (2026-10-17)

The maintainer requested proceeding to the next roadmap step. This delivery implements the boss fight; the dedicated gameplay boss health display and complete-phase acceptance remain step 5.

- Register a data-driven boss catalog in `WaveSpawnerConfig`, shipping one valid Dread Ark resource. The existing seeded director selects bosses and avoids repetition when alternatives exist; a single-boss catalog remains repeatable.
- At 300 regular seconds, cancel normal pending/deferred formations, suspend their budget, retire surviving enemies without rewards and recycle enemy shots. Materialize the boss deferred, with no overlap or stop/resume race. Survival time continues while regular scheduling time freezes.
- Use the approved 128×96, 12×8 Dread Ark atlas with attack preparation, discharge, recovery, hangar opening and core-transition ranges. Keep the existing original projectile and explosion artwork. The first phase fires two aimed three-shot fans; phase two alternates five-shot broadsides; phase three increases speed and cadence with seven-shot broadsides. The aim locks before discharge, preserving a dodge opportunity. No damaging beam is introduced in this bounded volley/reinforcement step.
- Apply 900 health solo and 1,440 in co-op, fixed for the run. At 66% and 33%, cancel the current attack for transition animations; crossing both thresholds in one hit still opens the hangars/core. Movement speeds, volley intervals/counts, telegraph duration and reinforcement pacing are resource data.
- From phase two, launch ordinary drones from the two bays, respecting six live/reserved reinforcements and the global 70/90 collision-body caps. Reinforcements use the run seed and cannot promote to elites. Normal spawning and debug N remain blocked throughout the fight.
- On death, disable boss collision/attacks safely, play its dedicated explosion, preserve score/power-up/plasma reward plumbing, retire adds and pooled enemy shots, then recover for eight seconds before a new encounter. Schedule the next milestone after five more regular minutes. A partner's death preserves the original co-op boss health; the last player's death stops all boss activity.
- Publish start/health/defeat events for the next HUD step. F10 already displays live boss health, phase, attack and reinforcement counts; the journal records start, phase changes and defeat without per-hit spam.

Validation in Godot 4.7.2: `tests/test_boss_encounters.gd` **143 checks PASS** in headless and native Compatibility runs, using real boss/enemy/projectile scenes for solo/co-op lifecycle, deferred cancellation, full-cap entry, stop with queued reinforcements, immunity during entry, threshold crossings, pooled volleys/speed, seed isolation, reinforcement reservations/caps, pause, recovery, recurring fights and partner/last-player death. Director **859**, continuous spawning **6,004**, elites **3,268**, progression/records **638**, debug **66**, and Alpha 9 combat **161** checks PASS. Fire input, beam and screen fades PASS. The normal-spawning suite explicitly isolates regular encounters; actual milestone boss integration is covered by the new suite.

Native Compatibility previews exercised both modes through all three charge/discharge sequences, debug inspection, defeat and recovery without runtime errors. Inspected captures: `.godot/phase_2_runtime_validation/boss_solo_phase1_charge.webp`, `boss_solo_phase1_fire.webp`, `boss_coop_phase2_charge.webp`, `boss_coop_phase3_fire.webp`, and `boss_coop_debug.webp`. These staged timing captures verify presentation and state flow; complete human solo/co-op balance playtests and the HUD remain pending. Existing animation-check and intermittent MP3 shutdown limitations are unchanged.

### Immediate boss debug shortcut

The maintainer requested direct boss access for testing. F12 forces the next seeded eligible boss through the existing entry path, without advancing either clock, changing danger, resetting the player's build or changing score. It is available only in debug-enabled, active regular gameplay; a paused inspector/menu must be closed first. Boss/recovery states and stopped/transitioning runs reject it, while held/repeated input cannot create overlapping bosses. The next natural milestone still follows five more regular minutes after defeat. The full inspector footer documents the shortcut. `tests/test_boss_encounters.gd` now includes F12 input mapping, main routing, all guards, state/clock/build preservation and solo/co-op materialization.

Validation: boss suite **171 checks PASS** in headless and native Compatibility runs; director **859** and debug screen **66** checks PASS. A native main-scene preview injected F12 through the viewport, confirmed the boss arrived before one second of survival, then opened F10 and visually verified the boss details and shortcut hint (`.godot/phase_2_runtime_validation/debug_boss_f12.webp`).

## Boss combat revision and gameplay health display (2026-10-17)

The maintainer requested faster projectiles, more reinforcements that focus players, more combat phases using the existing animation set, and the gameplay boss health bar. This supersedes the initial three-phase volley-only step; the wider normal-enemy rework remains deferred to Phase 4.

- Four combat phases at 75%, 50% and 25% health: dual aimed fans, hangar reinforcements and broadsides, faster seven-shot broadsides, then alternating broadsides and central beam. Resource validation supports variable phase counts with strictly descending thresholds and matching per-phase arrays.
- Raise boss projectile speed from 125 to 230 px/s and shorten volley cooldowns to 1.3/1.1/0.9/0.75 seconds. Preserve the gun charge/discharge/recovery sequences; alternate port and starboard shots after recovery. Use all 18 approved animation tags. Hangar reinforcements trigger at the launch frames rather than after the animation ends.
- Launch four drones solo or six in co-op, up to 12/18 live and reserved adds. Reinforcement intervals are 8/7/6/5 seconds, active from phase two. Both reinforcement and global body caps include deferred reservations.
- Give only boss reinforcements a resource-selected CHASE profile. Seeded assignments distribute targets across living co-op players, reassign after partner death, steer with bounded acceleration, then lock the trajectory within 100 pixels so a dodge can break pursuit. Normal drones keep their existing movement.
- In phase four, lock horizontal boss movement and show a harmless dashed beam corridor for 0.96 seconds. Fire the approved animated beam texture for 1.25 seconds, then cool down for 0.84 seconds. Only the 12-pixel bright core intersects actual player collision-shape bounds; a 0.15-second damage tick uses existing player invulnerability. The beam is a continuous hazard rather than a reflected projectile. Pause freezes animation/damage, and death or run stop cancels it synchronously without adding/removing physics objects in collision callbacks.
- Display name, phase, current/maximum HP and a continuous health bar above the combat area. The dedicated UI scene listens only to `Events`, uses no player/boss-node references, stays centered at wider aspect ratios, resets for recurring fights, and hides on defeat or interrupted game over.

Validation: boss lifecycle/combat **199 checks PASS** and new `tests/test_boss_pressure.gd` **40 checks PASS** in headless and native Compatibility runs. Coverage includes phase four beam sequencing, alternating guns, harmless telegraphs, collision bounds, escaping a beam lane, damage cooldown, pause, immediate stop/death, pursuing/committed drones, co-op retargeting, launch-frame synchronization, wave counts and event-driven/widescreen HUD behavior. Existing director **859**, spawning **6,004**, elites **3,268**, progression **638**, debug **66**, Alpha 9 **161**, native scale, player fire, player beam and screen-transition suites pass. Known old animation-check and intermittent MP3 shutdown limits remain separate.

Native solo/co-op captures inspect all four charge/discharge sequences, the beam corridor and continuous beam, pursuing formations, partially depleted health/phase labels, wider viewport alignment and defeat cleanup: `.godot/phase_2_runtime_validation/pressure_solo_phase1_fire.webp`, `pressure_solo_phase2_fire.webp`, `pressure_coop_phase3_fire.webp`, `pressure_coop_phase4_charge.webp`, `pressure_coop_phase4_fire.webp` and `pressure_coop_defeat.webp`. These staged captures validate presentation; final human boss balance acceptance is still required before closing Phase 2 or starting Phase 3.

### Segmented health presentation follow-up

The maintainer requested a Diablo-style segmented bar instead of numeric remaining health and phase text. Keep only the centered boss name and a continuous red bar, with dark separators and muted gold ticks at the actual resource thresholds. Dread Ark therefore has four segments separated at 75%, 50% and 25%. Threshold metadata arrives through `Events.boss_phase_thresholds_changed`; the HUD never reads boss nodes or hardcodes a phase count. Other bosses can provide uneven thresholds. Resize redraws the overlay while preserving continuous fractional-health fill. F10 retains its detailed diagnostic values.

Validation: `tests/test_boss_pressure.gd` **46 checks PASS**, including absent numeric/phase labels and resource-driven segment replacement; native-scale regression PASS. Refreshed native solo/co-op normal/wide captures verify full and partially depleted segments, centered name and no numeric/phase text (`pressure_solo_phase1_fire.webp`, `pressure_coop_phase4_fire.webp`).

### Pursuit follow-up

The maintainer reported that missed drones continued straight and requested slightly more speed. Remove permanent close-range trajectory commitment and the downward-only steering restriction. Boss drones now steer continuously toward their assigned living player, including upward turns after an overshoot, with the existing acceleration limit. Keep active pursuers inside the vertical viewport bounds so they can make another pass instead of disappearing off-screen. Raise pursuit speed from 110 to 125 px/s (about 14%); normal enemy movement remains unchanged. Chase assertions now exercise close-range retargeting, upward recovery and viewport containment. `tests/test_boss_pressure.gd`: **48 checks PASS**.

### Downward pursuit correction

The maintainer clarified that drones must never return upward after passing their player. Pursuit now ends permanently when the drone reaches its selected player's vertical position. It then steers downward and exits normally, without vertical viewport containment or renewed pursuit if the player moves ahead again. Retain 125 px/s pursuit speed and living co-op target reassignment before a pass.

Validation: `tests/test_boss_pressure.gd` **50 checks PASS** in headless Godot, including downward-only exit, leaving the viewport, permanent pursuit termination, increased speed and co-op retargeting.

### Missile targeting follow-up

Each salvo now samples the nearest living player's current position at discharge, including the first salvo after charging. Successive salvos therefore track player movement across the burst. Missiles retain their initial velocity after launch so players can dodge them. Burst spacing, animations and warning duration remain unchanged.

Validation: boss encounters **345 checks PASS** in headless and native Compatibility runs. Moving-target assertions cover the first discharge after charging, subsequent salvos across all four phases, actual projectile directions and unchanged velocities of previously launched missiles, in solo/co-op mode.

### Repeated missile salvos

Each missile attack now fires three complete salvos, 0.25 seconds apart, after the existing charge warning. Configure count and spacing in the boss resource. Preserve the locked target throughout the burst, replay the matching firing animation and sound for each salvo, then recover for 0.52 seconds after the final 0.21-second discharge animation. Phase one repeats both fans; later phases repeat the selected broadside and switch sides only after the full burst. Phase transitions and combat stop clear remaining salvos; normal scene pause freezes their timing.

Validation: boss encounters **303 checks PASS** in headless and native Compatibility runs; boss pressure **59 checks PASS**. Assertions cover salvo spacing/counts in every phase, target locking, recovery, gun alternation, pause, phase interruption, resource validation and projectile reuse. Native four-phase presentation checks PASS.

### Phase-four triple beam

Replace the single central lane with three simultaneous lanes under the left, central and right hull emitters, at scene-configured horizontal offsets of -40, 0 and 40 pixels. All three share the existing harmless 0.96-second warning, locked boss position, 1.25-second firing window and immediate stop/death cleanup. Each bright core remains 12 pixels wide, leaving safe gaps between lanes. A player overlapping several lanes receives at most one damage application per tick.

Validation: boss pressure **57 checks PASS** and boss encounters **199 checks PASS**. Coverage includes side-lane damage, harmless warnings, safe gaps, overlapping hitboxes, synchronized stop and scene offsets in solo/co-op. Native Compatibility presentation checks PASS. Refreshed `pressure_solo_phase4_charge.webp`, `pressure_solo_phase4_fire.webp` and `pressure_coop_phase4_fire.webp` confirm all three emitters, distinct warnings and uninterrupted lanes. Focused visual scores: `MOT-ANTIC` 2/2, `COMP-SIL-THREAT` 2/2, `LIGHT-PART-OCCLUDE` 2/2, `LIGHT-BLOOM-ABUSE` 2/2.

### Destructible missile cannons

Replace the large boss health hitbox with a 24-by-76-pixel central core. Separate 20-by-28-pixel left/right cannon zones each own 120 HP solo or 192 HP co-op, configured by `BossDefinition.cannon_health` and the fixed run co-op multiplier. Optional cannon damage never transfers to boss health or awards its kill reward. Non-overlapping hull armor polygons absorb projectiles with metallic impact feedback. All zones use the existing named enemy collision layer; child zones have their own group and do not count as enemies or consume encounter slots.

Normal/piercing player projectiles, continuous player lasers and shield-reflected enemy shots support the cannon zones. Cannon hits show a shader flash limited to that gun and a small nonnumeric health bar. Independent instance uniforms hold the flash for 0.04 seconds and fade it over 0.12 seconds; repeated hits restart only that side's tween. Core-hit feedback remains supported. Destruction plays a local explosion/sound, shakes briefly, disables the collider through deferred physics changes, and permanently changes the hull art. Only surviving missile guns emit salvos; later phases select the surviving side. Losing both guns cancels the current burst and suppresses subsequent missile charges. Each destroyed gun also removes its lateral beam immediately, including warning or active-fire states. The central beam keeps a 24-pixel damage core versus 12 pixels for side beams, with matching scaled artwork and warning width, regardless of surviving guns. Drones remain active, and disarmed phase four continues using its central beam on later cycles. Only core health controls boss phases, the segmented boss bar and final defeat. Stop/death disables every zone and cancels hazards. New encounters start with intact independent parts. F10 exposes both cannon health values and destruction flags.

Art: Aseprite MCP produced `assets/sprites/bosses/dread_ark_destructible_parts.aseprite` with separate hull, intact and destroyed cannon layers, plus three matching wreck-state PNG atlases. The original atlas is unchanged; its 87 animation frames and JSON layout remain compatible. Destroyed gun patches replace the corresponding muzzle flashes across all frames.

Validation: `tests/test_boss_parts.gd` **73 checks PASS** in headless and native Compatibility runs. Tests use real physics overlaps for cannon/core/armor projectiles, reflected shots, continuous beams and a lethal cannon collision, then check both destruction orders, surviving salvos, local shader parameters, immediate removal of active side-beam damage, wider central collision bounds, subsequent beam cycles, persistent art, independent solo/co-op health, fresh encounters, stop/death cleanup and resource validation. Regressions: boss encounters **345**, boss pressure **59**, debug screen **66**, player fire input and player beam presentation PASS. No script/physics errors; focused native part tests exit without retained-resource warnings. Full-world preview/suites may still emit the previously observed audio-resource shutdown warnings.

Native solo/co-op captures: `.godot/phase_2_runtime_validation/parts_solo_shader_hit.webp`, `parts_solo_damaged.webp`, `parts_solo_port_destroyed.webp`, `parts_solo_surviving_gun.webp`, `parts_solo_port_destroyed_beams.webp` and `parts_coop_both_destroyed_beams.webp`. Native before/after pixel comparisons confirm the hit shader changes the left gun while preserving the right gun and core. Reviewed local health feedback, explosion, wreck persistence, surviving muzzle animation, missing destroyed-side beam and wider central beam, and unchanged boss health after optional-part damage. Focused visual scores: `COMP-SIL-THREAT` 2/2, `LIGHT-PART-OCCLUDE` 2/2, `LIGHT-BLOOM-ABUSE` 2/2. Final human boss balance acceptance remains pending.

### Chained final destruction

Boss defeat now creates a world-owned cosmetic effect, independent of the retiring boss actor. Snapshot the current hull frame and wreck texture, then play eight spatially distributed explosions at 0.12-second intervals. The hull fades before a 192-pixel central blast at 0.96 seconds, with an expanding shockwave and a short warm flash. Small blasts request brief shake; the final blast requests strength 52 for 1.15 seconds. Scripted heavy impacts can reach a camera amplitude of 26 logical pixels, twice the ordinary 13-pixel cap, while existing combat impulses retain their original limit. Smaller incoming impacts preserve the stronger ongoing shake. The existing HUD canvas remains stationary. Reuse approved explosion textures and audio. Visual effects expire within 1.9 seconds, the final shake ends by 2.11 seconds, and both pause with gameplay. Combat shutdown, rewards, defeat events and the eight-second recovery still start immediately and exactly once.

Validation: `tests/test_boss_death_effect.gd` **19 checks PASS**, including timed bursts, one final shock, pause, world ownership after boss removal, cleanup, actual maximum camera shake, roughly doubled displacement using identical noise samples, preserved ordinary impact limits, and complete camera recovery. Refreshed native sequence captures (`death_hull_chain_1.webp`, `death_hull_chain_2.webp`, `death_core_blast.webp`, `death_shockwave.webp`, `death_cleared.webp`) verify the visible hull breakdown, stronger final blast, shockwave, stable HUD and restored camera. Boss parts **73**, boss encounters **345**, boss pressure **59** and debug **66** checks PASS after integration. Focused motion/FX review: `LIGHT-PART-OCCLUDE` 2/2 and `LIGHT-BLOOM-ABUSE` 2/2; death FX stay below HUD and reuse the established pixel-art style.

### Regular hunter drones and committed approach

Add an inherited `drone_hunter.tscn` scene alongside the original drone, sharing its enemy definition, health, rewards, elite eligibility and threat cost. Hunters default to the existing chase movement resource; ordinary drones retain sine formations. Encounters 00, 03, 06, 09, 12 and 15 split one existing drone rule into 0.65 formation-drone weight and 0.35 hunter weight. Both versions retain the original formation size, pattern, lanes, interval and spawn gap, preserving the combined selection weight, threat budgets, encounter count and solo/co-op body caps. Other enemy families and encounters are unchanged. This is the maintainer's bounded drone adjustment; the full Phase 4 roster/density redesign remains deferred.

The shared pursuit profile now exposes `chase_commit_distance = 64`. When the selected player's vertical separation reaches this threshold, the hunter permanently stops steering and retains its current velocity. It no longer bounces at horizontal bounds during that final straight approach, and never turns back upward or reacquires a target after committing. Earlier co-op target reassignment remains supported. Speed stays 125 px/s before director/elite modifiers. Boss reinforcements use the same hunter scene, behavior and art.

Aseprite MCP created RGB magenta hunter sheets with a small nose marking and preserved explosion frames, plus editable `.aseprite` sources under `assets/sprites/enemies/animation_rework/`. The elite variant retains gold markings and the existing 8-by-4 animation layout, without an overhead health bar as requested by the maintainer. Other enemy families retain their elite bars. The inherited scene explicitly declares the shared drone definition so the spawner's scene-resource lookup resolves its family without instantiating it.

Validation: `tests/test_drone_hunters.gd` **595 checks PASS** for catalog weight conservation, scene definitions, early commitment, unchanged straight velocity after dodges/edge crossings, normal drone behavior, visible imported magenta/gold pixels, solo/co-op spawning, budgets/caps and deterministic traces. Regressions: encounter spawning **6,112**, elites **3,268**, Alpha 9 **161**, boss encounters **345** and boss pressure **59** checks PASS. Native solo/co-op presentation verifies normal/hunter/elite differentiation and constant velocity after commitment (`hunters_solo_lineup.webp`, `hunters_solo_lineup_detail.webp`, `hunters_coop_lineup.webp`, `hunters_coop_commit_1.webp`). Visual checks: `COMP-SIL-THREAT` 2/2 and `LIGHT-PLAY-SEP` 2/2. Existing intermittent audio-resource shutdown warnings remain unchanged.

### Localized core hit feedback

Mask the boss's existing core-hit shader flash to the central 24-by-76-pixel damage zone instead of illuminating the whole hull. Preserve independent cannon flashes and existing hit timing. Boss parts **73 checks PASS**. Native solo/co-op pixel comparisons confirm that a real core hit changes central pixels while leaving both guns and wing armor unchanged (`parts_solo_core_shader_hit.webp`, `parts_coop_core_shader_hit.webp`). Visual check: `LIGHT-HIT-FLASH` 2/2.

### Three-phase pacing and dynamic movement

The maintainer found four phases too long, the motion too linear and health excessive. Consolidate combat into three phases at 65% and 30% remaining core health: dual missile salvos; alternating missile salvos with hunter launches; then seven-shot salvos alternating with telegraphed beams and continuing reinforcements. Retain the hangar-opening and core-opening transitions and the approved animation atlas. The segmented bar now has three sections supplied by the resource thresholds. Destructible cannons, localized hit feedback, wide central beam, chained death effects, rewards, milestones and recovery rules remain intact.

Reduce core health from 900 to 650 solo and from 1,440 to 1,040 co-op (about 28%). Reduce each cannon from 120 to 90 solo and from 192 to 144 co-op (25%). Co-op health remains fixed for the run even after one partner dies.

Replace constant-speed horizontal bouncing with a six-position route selected by the existing movement seed. The boss accelerates toward varied lateral/vertical goals, brakes on approach, and rests for 0.35 seconds at arrivals. Phase speeds are 55/80/105 px/s, horizontal ranges 88/120/144 pixels and vertical range 14 pixels. Discharge slows movement to 55% of its phase speed. Warning, firing and recovery for beams freeze both axes and reset movement velocity so the displayed lanes stay fixed. All tuning values live in the boss resource; movement consumes no additional gameplay RNG draws.

Validation: `tests/test_boss_movement.gd` **1,212 checks PASS** for bounded movement, acceleration, rests, height changes, multiple direction changes, seeded reproducibility, increasing phase speeds, frozen beam lanes and invalid motion data. Updated boss lifecycle **309**, parts **73**, pressure **59**, death effects **19**, Alpha 9 **161** and debug **66** checks PASS. Native solo/co-op three-phase sequence checks PASS, including resource-driven segmentation, final-phase beams, and frame sequences showing movement at different times (`pressure_solo_phase1_move0.webp`, `pressure_solo_phase1_move2.webp`, `pressure_coop_phase3_fire.webp`). Focused review: `COMP-SIL-THREAT` 2/2, `MOT-ANTIC` 2/2. These staged checks verify behavior and presentation; final human balance acceptance remains pending.

### Player beam first impact

Use a width-aware shape cast to stop each player beam at the first obstacle's collision surface. Only that obstacle receives damage; destroying it reveals the next target immediately. Include obstacles already overlapping the emitter and ignore destroyed actors. Match the beam line, halo and collision geometry to the endpoint, with impact feedback at the contact point. Preserve normal/overdrive widths, damage cadence and independent co-op beams.

Validation: `tests/player/test_beam_impact.gd` **18 checks PASS** for nearest-target selection, surface endpoints, protected targets behind obstacles, emitter overlap, overdrive width/damage, boss armor/core/cannons, independent co-op probes and deactivation. Existing beam effects, player fire input, shield throwback and boss parts **73 checks PASS**. Native solo/co-op presentation checks PASS for first impact, reveal after destruction and separate boss core/cannon endpoints (`player_beam_solo_first_impact.webp`, `player_beam_coop_boss.webp`).

### Dedicated hunter interceptor sprites

Replace the interim magenta recolor with new pixel art drawn through Aseprite MCP: an arrowhead interceptor with swept wings, a steel hull, red sensor and twin exhausts. Elite hunters gain gold wing armor with a slightly wider silhouette. Both editable sources now use 32-by-32-pixel animation frames with separate hull/explosion layers and named idle, explosion and banking tags. Export the existing 16-by-1 normal and 8-by-4 elite atlas layouts; preserve all nine explosion cells exactly. Align hunter reactor particles to the new exhausts. Movement, collision shapes and combat data remain unchanged.

Validation: hunter suite **596 checks PASS**, including imported hull shading and actual silhouette differences from formation drones and between normal/elite interceptors. Native solo/co-op lineup and committed-approach preview PASS (`hunters_solo_lineup_detail.webp`, `hunters_coop_commit_1.webp`). Reviewed `COMP-SIL-THREAT` **2/2** for a distinct arrowhead outline and elite armor, and `LIGHT-PLAY-SEP` **2/2** for readable steel edges and sensor details against the gameplay background. Existing intermittent audio-resource shutdown warnings remain unchanged.

### Hunter palette and heading correction

The first bespoke sprites used an unapproved blue-steel ramp and excessive bright metal, which did not match Dread Ark. Rework both Aseprite sources and exports with the shared Lost Warden 64 palette: Void, Deep Space and Hull Shadow dominate; Gunmetal and short Steel edges define the hull; Warden Red/Ember mark the sensor and engines. Elite armor uses restrained Amber/Warm Copper accents. Load the complete official palette in each editable source and use discrete palette shades for bank frames.

Inherited banking animations previously left the nose pointing down regardless of the chase velocity. Hunter presentation now faces its actual velocity, including near-horizontal approaches, while preserving the root transform and collision footprint. Both exhaust positions and their emission directions follow the hull. Zero velocity preserves heading, and the committed approach remains straight. Formation drones retain their existing banking behavior.

Validation: `scripts/art/audit_palette.py` reports **2 PNGs checked; 0 outside palette** across the complete normal/elite atlases. Hunter suite **650 checks PASS**, covering palette membership, structural tones, both turn directions, exhaust alignment, unchanged collision transforms and committed heading/trajectory. Native boss comparison verifies normal/elite left, down and right headings alongside Dread Ark (`hunter_boss_heading_detail.webp`); existing solo/co-op approach preview also PASS. Reviewed `COMP-SIL-THREAT`, `LIGHT-PLAY-SEP` and heading-to-trajectory continuity at **2/2**. The isolated boss comparison exits cleanly; the existing full-world preview retains its intermittent audio-resource shutdown warning.

### Faster hunters and downward exit

Increase the shared hunter profile's chase speed from 125 to 175 px/s (40%), initial downward speed from 100 to 140 px/s and acceleration from 240 to 340 px/s². Preserve spawn and elite speed multipliers. Hunters still commit 64 pixels before reaching their selected target. Capture that target's height at commitment; after crossing it, progressively steer to a vertical downward exit using the profile acceleration. This state is permanent, including after dodges, co-op target loss or crossing horizontal bounds. Hull and exhaust orientation follow the changing velocity. Ordinary formation drones are unchanged.

Validation: hunter suite **914 checks PASS** for both lateral approach directions, normal/elite speeds and modifiers, committed attacks, gradual downward acceleration, target loss, final vertical heading and seeded spawn traces. Boss pressure **59 checks PASS** with the faster shared reinforcements. Native solo/co-op approach, turn and vertical-exit sequences PASS (`hunter_exit_solo_approach.webp`, `hunter_exit_solo_turn.webp`, `hunter_exit_solo_down.webp`, corresponding co-op images). Reviewed heading-to-trajectory continuity and exit readability at **2/2**. These fixed-step captures are presentation checks, not performance measurements; the existing full-world shutdown audio warning remains unchanged.

### Boss beam sustained contact damage

Previously, repeated beam calls were blocked by the player's ordinary hit protection; the supplied damage amount was also intentionally ignored by the one-energy-per-impact vitals system. Add a dedicated continuous-hazard entry point that retains the normal hit/death feedback while allowing the beam's own cadence to govern exposure. Ordinary shots and collisions keep their existing protection.

The boss resource now authors `beam_damage_interval = 0.35`: one energy point on contact, then one per interval while intersecting a live beam core. Per-player cooldowns prevent overlapping lanes and rapid reentry from multiplying damage. Leaving stops damage; warning/fire/stop reset contact state, pause freezes the clock, and destroyed cannons immediately remove their lane. Dying players and disabled colliders remain excluded. With three starting energy points, uninterrupted exposure can be lethal within the 1.25-second firing window.

Validation: `tests/test_boss_beam_damage.gd` **20 checks PASS** using real player scenes for ordinary protection, repeated beam energy loss, independent co-op entry, reentry, exit, cannon-lane removal, disabled collision, stop, death and invalid cadence data. Existing boss parts **73**, Alpha 9 balance **161** and shield throwback checks PASS. Boss pressure also verifies resource-to-runtime cadence. Native co-op warning/contact/sustained/exit comparison PASS with matching energy HUD changes (`boss_beam_contact_entry.webp`, `boss_beam_contact_exit_vs_stay.webp`); the isolated preview exits cleanly. Reviewed `LIGHT-HIT-FLASH` **2/2** for repeated contact feedback. Beam shapes and artwork remain unchanged.

### Two-phase attack-pattern rework

Status: implemented from the maintainer-approved two-phase plan on 2026-10-17. Final human balance acceptance remains pending; Phase 3 is unchanged.

Reduce Dread Ark to two gameplay phases with one threshold at 50%, preserving 650 solo / 1,040 co-op core health and 90 / 144 cannon health. Entry opens the hangars; the only health transition opens the core. Idle presentation uses the existing hangar-open and core-open atlas ranges. The HUD receives one threshold through the existing event bus, producing two segments. F10 now reports both the attack state and active pattern; F12 retains the normal guarded boss-entry path.

`BossAttackPattern` resources replace the old fixed-volley/cooldown fields with authored AIMED, RINGS, SPIRAL, DRONES and BEAM entries. Phase one cycles rings, aimed salvos, spiral, aimed salvos, drones. Phase two cycles rings, aimed salvos, spiral, beam, aimed salvos, drones. Missile attacks charge for 0.6 seconds, recover for 0.4 seconds and leave a 0.35-second pause between attacks. Existing animations, projectile sprites, sounds and pooling remain in use.

| Pattern | Phase one | Phase two |
| --- | --- | --- |
| Rings | Two 24-slot rings at 145 px/s, 0.38 seconds apart | Three 32-slot rings at 165 px/s, 0.32 seconds apart |
| Spiral | Two opposed arms, 10 emissions, 0.10-second interval, 12-degree step, 145 px/s | Two opposed arms, 14 emissions, 0.08-second interval, 18-degree step, 165 px/s |
| Aimed | Both living cannons, five missiles each, three salvos | One living cannon at a time, seven missiles, four salvos |
| Drones | Two solo / three co-op per launch | Two solo / three co-op per launch |
| Beam | None | Existing 0.96-second warning, 1.25-second firing, 0.84-second recovery |

Each ring omits a 45-degree sector initially centered 35 degrees to one side of the locked player direction. Successive attacks alternate the opening side. Within an attack, the ring and opening advance 15 degrees per emission, preserving the full opening and a shared overlap between rings. The resulting counts are 21 / 28 missiles per ring. A lightweight core warning shows the opening edges. Spirals alternate direction between uses; their directional warning arcs were removed at the maintainer's request, preserving the charge animation and timing. Circular patterns originate from the central emitter and remain available with both cannons destroyed. Aimed salvos travel at 230 px/s with 0.25-second spacing and reacquire aim between salvos; all released missiles retain their velocity.

The shared drone cap is four solo / six co-op, including pending reservations. Launches require room for a complete group; a full launch slot is skipped. No new missiles or drone launches occur during beam states. A destroyed cannon immediately loses its targeted salvos and lateral beam. Its destruction cannot interrupt a core pattern. Phase changes cancel pending launches and recycle owned missiles before their visual transition; stop/death also clear owned missiles and emission clocks without touching unrelated projectiles.

Movement now uses phase speeds 80 / 115 px/s, horizontal ranges 120 / 144 pixels, acceleration 220 px/s² and 0.15-second arrival rests. Height variation remains 14 pixels. Firing slows travel to 55%, while beam warning/fire/recovery lock both axes. Pattern orientation and route use the spawn seed without consuming cosmetic randomness.

Validation: pattern suite **893 checks PASS** for quantities, speeds, 45-degree gaps, ring shifts, spiral direction/spacing, exact cycles in solo/co-op, disarmed core attacks, full drone-slot skipping, pause, long-frame emission scheduling, owned-projectile cleanup, transition/death/stop cancellation, invalid data and reproducible missile traces. Boss encounter lifecycle **393**, movement **1,212**, parts **73**, pressure **61**, death sequence **19**, continuous beam damage **20**, encounter director **859**, encounter spawning **6,112**, hunter drones **914**, Alpha 9 **161**, debug **66** and player beam impact **18** checks PASS. Shield throwback PASS; the wall-clock-sensitive fire-input test passed when rerun alone after a concurrent-run failure.

Native GL Compatibility F12 previews verify every pattern and both phases in solo/co-op, including warnings, two-segment health, drone caps, beams, and circular fire with both guns destroyed (`two_phase_solo_p1_ring_warning.webp`, `two_phase_solo_p1_rings.webp`, `two_phase_solo_p2_spiral.webp`, `two_phase_coop_disarmed_rings.webp`). Visual review: `COMP-SIL-THREAT` **2/2** for separated missiles/openings, `LIGHT-PLAY-SEP` **2/2** for preserved projectile contrast, and `MOT-ANTIC` **2/2** for harmless preparation cues and locked beam lanes. These captures are presentation evidence, not a performance benchmark. Existing intermittent audio-resource shutdown warnings remain in full-world previews; no script or physics errors were reported.

### Natural boss arrival and central-cannon presentation — 2026-10-18

Implemented the approved arrival, artwork and drone follow-up. The two phases, health, pattern quantities/speeds and beam dimensions/damage/duration retain their current settings. Phase 3 has not started. Human balance acceptance remains pending.

Natural milestones select one boss and enter `BOSS_APPROACH`. New formations and pending regular spawns stop; existing enemies, patrol turrets, asteroid fragments and enemy shots continue normally. Once enemies/reservations and enemy projectiles are gone, a 0.5-second calm window precedes boss materialization and its health-bar event. Player shots do not block arrival. Survival time advances, regular scheduling freezes, pause freezes the wait, and stopping or removing the screen cancels deferred arrival. F12 retains immediate debug cleanup. The full inspector exposes the approach state and calm timer.

Rings and spirals originate from `MainMuzzle` at (0, 42), including ring warning geometry. They retain the phase hull animation and use a separate local AnimatedSprite2D: charge 0.6 seconds, fire looping every 0.3 seconds, recovery 0.4 seconds. Subsequent emissions do not restart the flash or hull animation. Spirals have no directional warning. Cannon wrecks and actual beam animations remain intact.

New editable Aseprite sources: `assets/sources/combat/dread_ark_muzzle.aseprite` and `dread_ark_orb.aseprite`. Their sprite sheets live in `assets/sprites/combat/`. The orb has four 16 × 16 cells, an eight-pixel visible circular silhouette, red glow and bright core without an elongated trail. The palette audit reports **two sheets checked, zero colors outside Lost Warden 64**. `scenes/bosses/dread_ark_orb.tscn` has its own ProjectilePool bucket, keeps the existing missile collision/damage and disables velocity-based orientation. Aimed salvos still use the original elongated missile scene. The shield can reflect and recycle either type.

Drone launch sizes are now **four solo / six co-op**, with caps of **eight / twelve including reservations**. The existing cadence, complete-group eligibility and beam exclusion remain in place.

Automated verification using Godot 4.7.2 in the isolated runtime project:

| Suite | Checks passed |
| --- | ---: |
| Natural approach, cancellation, pause, fragments, late shots, F12 | 18 |
| Main muzzle, animation continuity, orb shape, separate pool reuse, shield reflection | 52 |
| Patterns, phase changes and deterministic solo/co-op traces | 893 |
| Boss encounters and reinforcement reservations/caps | 396 |
| Boss pressure | 61 |
| Encounter director | 860 |
| Encounter spawning and debug skip | 6,113 |
| Boss movement / cannon parts / death sequence | 1,212 / 73 / 19 |
| Continuous beam damage / player beam impact | 20 / 18 |
| Hunter drones / Alpha 9 / debug inspector | 914 / 161 / 66 |

Shield throwback and isolated fire-input regressions PASS. Editor import completes without script errors and `git diff --check` finds no whitespace errors. Headless editor startup also reports a Windows safe-save warning without identifying a target path; it reproduces with a separate APPDATA directory. Both new textures and script UIDs are present and load successfully in the runtime checks. The debug-skip fixture now constructs its spawner directly under the final parent: removing a running spawner from the tree intentionally cancels arrival and cannot serve as neutral fixture setup.

Native GL Compatibility captures in `.godot/phase_2_runtime_validation/`:

- `natural_approach_preserved.webp`, `natural_approach_fragments.webp`, `natural_approach_boss_entry.webp`: actual movement, turret patrol/fire, asteroid destruction/fragments and projectile exits complete before automatic boss entry, without deleting surviving actors. This preview completes cleanly after 1,072 physics frames of approach.
- `main_cannon_solo_p1_ring_warning.webp`, `main_cannon_solo_p2_spiral.webp`, `main_cannon_coop_p2_salvos.webp`: both phases, round central shots, local preparation and preserved aimed missiles.
- `main_cannon_solo_one_cannon_rings.webp`, `main_cannon_coop_disarmed_rings.webp`: circular patterns remain readable with one or both cannon wrecks, alongside the intact-cannon captures. The full solo/co-op preview also covers drone groups and beam warning/fire.

Visual review: `COMP-SIL-THREAT` **2/2** for round projectile silhouettes and openings, `LIGHT-PLAY-SEP` **2/2** for projectile contrast, `MOT-ANTIC` **2/2** for local preparation while preserving the phase hull. Native previews validate presentation rather than real-time performance or final difficulty. Full-world pattern previews and the debug suite still report the previously observed audio-resource shutdown leaks; the new approach/presentation suites and natural-arrival preview complete cleanly. No script or physics errors occur in the successful verification runs.

### Attack indicator and pattern tuning — 2026-10-18

Maintainer follow-up removes the projected ring arc/opening guides and the beam's translucent/dashed lane indicators. Local cannon charge effects and the hull's beam-charge animation remain, with unchanged harmless preparation times, actual beam rendering and damage. The ring opening is now 30 degrees rather than 45, yielding 22 / 29 projectiles per ring. Spirals retain their two arms, speeds, angular steps and intervals but emit 16 / 20 times rather than 10 / 14: first-to-last emission spans 1.50 / 1.52 seconds instead of 0.90 / 1.04 seconds.

Verification: patterns **957**, beam damage **22**, central-cannon presentation **52**, cannon parts **73** and boss encounters **396** checks PASS. The beam test verifies that preparation remains hidden and actual firing becomes visible. The F12 test fixture now creates its running spawner under the final world parent, preserving the screen-removal cancellation contract. Native solo/co-op previews PASS; inspected `boss_tuning_solo_p1_ring_warning.webp`, `boss_tuning_coop_beam_warning.webp` and `boss_tuning_solo_p2_spiral.webp` confirm absent projected indicators and the longer spiral. Captures use the same isolated runtime directory. Visual review: `COMP-SIL-THREAT` and `LIGHT-PLAY-SEP` **2/2**; local charge animations remain the preparation cue. Previously recorded shutdown resource warnings still occur in the full-world preview. Final difficulty remains subject to gameplay acceptance.
