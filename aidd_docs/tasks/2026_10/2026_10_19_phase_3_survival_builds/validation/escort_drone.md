# Step 9 — escort drones

Verified on 2026-10-21 with Godot 4.7.2. The maintainer accepted the missile checkpoint, requested its local commit (`30818a6`), then authorized the escort checkpoint and the following visual/count revision. This checkpoint remains local for playtest.

## Playable result

- One / one / two companions at ranks 1 / 2 / 3. The maintainer explicitly selected the second drone at rank three. Each family occupies one offensive slot, irrespective of companion count.
- Shoulder anchors are (+24,-12) then (-24,-12), mirrored for P2. Supports have no collision object. At the arena edges the rendered hull, emitter and reactors tuck inward; player movement bounds and the fixed shoulder anchors are unchanged.
- Nearest eligible visible target within 180 px and a 90-degree screen-up cone (+/-45 degrees) of each emitter; stable spawn identity resolves ties. Aim is captured at emission. Bolts fly straight at 360 px/s for one second, with no homing or leading.
- Authored per-bolt damage 0.6 / 0.75 / 0.9 and per-companion intervals 0.65 / 0.55 / 0.45 seconds. Common DAMAGE applies once; FIRE_RATE uses manual delay / 0.20, with minimum factor 0.6. Both companions share six active/reserved bolts per owner. No target retains readiness; saturation consumes an interval without queuing a backlog.
- Drone bolts use the existing pool and accepted-hit service. They roll direct criticals once at emission and preserve boss-group exclusion. The maintainer later excluded electric chains from drone bolts, superseding their initial chain compatibility. Dormant cannon-piercing compatibility remains tested; piercing is not restored to live cannon offers. Missile chain exclusion remains intact.
- Acquisition creates the support immediately; upgrading to rank three preserves the original and adds the opposite companion. Generic input reset preserves them, pause freezes presentation/cadence/flight, and DYING removes both supports and pending requests. Already airborne direct bolts may finish without new owned procs.
- Hulls use dedicated idle/left/right frames following Nomad movement. Their twin reduced reactor copies use the player's existing smoothed amount, speed, length, brightness and team gradients. Forward thrust, braking and idle therefore match the ship without a second reactor tuning model.

## Verification

| Check | Result |
| --- | --- |
| `tests/player/test_escort_drone.gd`, native OpenGL | **344 checks, zero failures**, clean shutdown |
| `tests/test_upgrade_offers.gd`, native | **2,133 checks**, zero failures |
| `tests/test_progression_activation.gd`, native | **76 checks**, zero failures |
| `tests/player/test_micro_missiles.gd`, native | **458 checks**, zero failures |
| Additional accepted-hit / chain / critical regressions in this checkpoint | **42 / 144 / 708 checks**, zero failures |
| Fresh editor language-server diagnostics | **85 game scripts + four combat tests**, zero errors/warnings |
| Aseprite composite/export equality | **Zero differing pixels** for escort, bolt, menu and miniature pairs |
| Lost Warden 64 and alpha | All four runtime PNGs use exact palette colors and binary alpha |
| Existing menu and miniature columns | First fourteen columns remain pixel-identical to `30818a6` |
| `git diff --check` | Pass |

The drone fixture covers all ranks and common-stat extremes, real physical impacts, target movement after emission, no-target readiness, exact range boundary, occlusion, target ties, critical replays for both owners, recursive-proc exclusion, legacy piercing decay, boss-group exclusion, pool reset, two-owner capacity with two companions each, manual plasma coexistence, paused flight/timers/presentation, DYING and repeated world destruction with/without supports.

Native ignored captures in `.godot/phase_2_runtime_validation/` were inspected: `escort_drone_{solo,native,wide}.webp`, `escort_drone_motion_{solo,native,wide}_{-1,0,1}.webp`, `escort_drone_edges_{solo,native,wide}_{top,bottom}.webp` and `escort_drone_choices_{solo,native,wide}.webp`. They show both owner colors, ranked pairs, banks, thrust/braking response, edge placement and the updated 64px cards / 16px miniatures. An initial raw-PNG reference sampling artifact was corrected in Aseprite before the final imports/captures.

Effect balancing and human co-op acceptance remain deferred. No satellite, explosion, ricochet, permanent progression or dedicated audio work was added. Stop for maintainer playtest; step 10 satellites are the next requested checkpoint.

## Forward-fire follow-up — 2026-10-21

The maintainer requested angular limits in front of each support. Reuse the weapon's authored `forward_angle_degrees = 90` and the existing cone filter before nearest-target selection. No-target readiness is preserved for rear/lateral-only enemies. The range remains 180 px and fired bolts keep their original straight vector. Card text now identifies forward escorts. Invalid nonfinite, nonpositive or wider-than-180-degree resource cones reject before offers.

The added fixture reproduced 29 failed assertions before the correction. It covers both players, both rank-three shoulders, nearer rear/lateral decoys, points just outside the cone, and inclusive +/-45-degree boundaries. Existing rank-flight fixtures now keep their common target inside both shoulder cones. Boundary fixtures use 48px offsets to avoid the enemy's own arena-entry clamp and remove occluding outside-cone surfaces before testing the boundary in isolation.

Verification after the forward-fire revision: **407 native escort checks**, **2,133 offer checks**, **434 headless missile checks** and **132 headless chain checks** pass. The native escort run exits cleanly; forward-only card captures were inspected.

## Gliding follow-up — 2026-10-21

The maintainer approved a subtle trailing/hover experiment. Add bounded inertia from actual owner displacement, smooth exponential settling, and deterministic per-shoulder/per-owner hover phase without consuming gameplay RNG. Hull, muzzle and reactor mounts move together; integer displacement precedes the existing arena clamp. Banking and reactor response remain unchanged, and the 90-degree targeting cone follows the visible emitter.

**445 native checks pass**, with a clean shutdown. Added checks cover independent phases, lag direction and maximum displacement, emitter/hull alignment, zero elapsed time, settling without drift, relocation bounds and frozen glide during selection pause. Existing rank, targeting, real-contact, capacity and lifecycle cases also pass. Native `escort_drone_glide_{10,14,47}.webp` captures were inspected for following, reversal and settling; the full sequence also includes frames 0/26. `git diff --check` passes. No new art, audio, combat stats or later roadmap step was introduced.

## Drone lightning exclusion — 2026-10-21

The maintainer requested that escort shots stop triggering electric chains. Strip `energy_chains` from emitted drone snapshots and reject both DRONE and MISSILE sources at chain resolution. This preserves direct damage, criticals, legacy piercing compatibility and normal cannon chain behavior.

The updated contact fixtures reproduced 12 failing assertions before the fix. Final native runs pass **460 drone checks**, **144 energy-chain checks** and **458 missile checks**, with clean exits. Both owners are tested through real physical critical impacts and intentionally unfiltered DRONE packets: nearby enemies remain untouched, no arc visual/root/cooldown is created, and the same owner's ordinary cannon immediately triggers its normal chain. `git diff --check` passes. This supersedes the initial drone/chain compatibility in this document.
