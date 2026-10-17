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
