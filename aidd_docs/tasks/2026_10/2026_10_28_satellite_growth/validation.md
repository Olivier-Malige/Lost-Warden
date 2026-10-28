# Three satellites with ranked size and damage — 2026-10-28

The maintainer requested three Orbiting Satellites from the first acquired rank, with upgrades increasing size and damage rather than count. Implemented locally as a scoped Phase 3 family revision. No commit or publication requested.

## Current contract

| Rank | Satellites | Visual size | Core contact radius | Direct damage |
| --- | ---: | ---: | ---: | ---: |
| 1 | 3 | 100% | 4px | 1 |
| 2 | 3 | 125% | 5px | 1.5 |
| 3 | 3 | 150% | 6px | 2 |

Values are authored in `data/upgrades/orbiting_satellites.tres`. `UpgradeDefinition.size_scales` validates finite, positive, nondecreasing rank sizes and exposes the next size in detached offer snapshots. Satellite validation requires exactly three supports at every rank. The card describes three satellites, base/+25%/+50% size and authored contact damage.

Ranking grows the existing three Sprite2D nodes and updates their individual CircleShape2D radii in the existing deferred rebuild. Collider nodes stay unscaled and unrotated. No orbiter is replaced on rank-up, and orbit phase, spin phase, contact cooldowns and flashes are preserved. Existing steel art, team inserts, 32px orbital radius, 1.25s orbit, 0.625s independent spin and one offensive slot remain.

The owner/group cooldown is still 0.50s, scaled only by FIRE_RATE down to 0.30s. Three simultaneous orbiters cannot multiply a single group tick. Common DAMAGE, personal critical streams, physical contact, impact explosions and the main-cannon-only electric-chain policy remain. Satellites do not block enemy shots or change the player's hull/bounds. P1/P2 cooldowns and state stay independent. These are playtest values, not final global balance acceptance.

## Verification

Godot 4.7.2, addon-free `.godot/phase_2_runtime_validation/` project, isolated APPDATA. Native runs use OpenGL Compatibility on the RTX 3060.

| Suite | Checks | Result |
| --- | ---: | --- |
| Satellites, headless | 315 | Pass; clean exit |
| Satellites, native | 408 | Pass; stderr empty |
| Upgrade offers | 4,531 | Pass |
| Impact explosions | 203 | Pass |
| Upgrade selection | 76 | Assertions pass; existing shutdown warning below |

Satellite checks cover counts, size/shape agreement, reuse of the same orbiters, phase continuity, rank damage, invalid resource rejection, shared contact cadence at base/max FIRE_RATE, personal co-op RNG, boss group deduplication, moving enemy crossings, projectile pass-through, critical/explosion rules and safe pause/death/world cleanup. A real enemy outside the rank-one core is reached after size growth at rank two; rank three preserves the active cooldown and cannot grant an extra contact hit.

Native captures include all three ranks in solo/co-op/wide layouts, plus moving hunter contacts, playfield edges and selection cards. Inspected `satellites_rank_1_coop.webp`, `satellites_rank_3_coop.webp`, `satellites_rank_2_solo.webp` and `satellites_choices_coop.webp`: exactly three steel orbiters remain distinct around each owner, larger ranks are visibly larger, team inserts remain legible, and size/damage text fits both personal cards. Existing sprites/icons were retained; no generated art was introduced. Logs `satellite_growth_native.log` and `satellite_growth_native_errors.log` are in the ignored validation project.

An initial test formatting helper leaked three temporary CanvasLayers; the helper now frees them and both satellite suites were rerun cleanly. The selection suite still reports the previously documented two-object/one-resource shutdown warning; no audio code was changed. `git diff --check` passes. Previous gameplay changes and local MCP activation edits were preserved.
