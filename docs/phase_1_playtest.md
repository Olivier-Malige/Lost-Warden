# Phase 1 Playtest Record

Status: pending hands-on solo and local co-op sessions. This record does not approve Phase 1.

Runtime smoke check (2026-09-22): Godot 4.7.2 opened the main scene without reported startup errors; solo and local co-op both reached the world scene. This does not assess combat feel or wave readability.

## Setup

- Run the current project in a Godot debug build with the GL Compatibility renderer.
- Test solo first, then local co-op. Use F2 to advance one wave and F1 to return one wave; verify the HUD wave number after each jump. Restart between modes.
- At each target wave, play long enough to see the full formation and its exit. Record the build revision, display size, input devices, and any issue with a timestamp or screenshot.

| Wave | Solo | Co-op | Main observation |
| --- | --- | --- | --- |
| 1–3 | Pending | Pending | Drone arcs, initial pace, projectile visibility |
| 6 | Pending | Pending | Lane spacing and collision readability |
| 9 | Pending | Pending | Turret telegraphs and aimed/radial shots |
| 12 | Pending | Pending | Mother ship arrival, modules, and shot density |
| 15 | Pending | Pending | Mixed enemy paths and pickup visibility |
| 18 | Pending | Pending | Dense combat, elite recognition, and performance |

## Checks in each mode

- Move idle, while firing, and while using the beam. Note whether the 0.88 weapon speed feels controllable and whether damage feedback obscures movement.
- Collect plasma cells, activate the beam above the minimum reserve, release it early, and try a full-reserve overdrive. Note whether the primary cannon remains useful.
- Watch enemy paths, shot glows, foreground streaks, hit flashes, and camera shake together. Note unclear collisions or shots lost against the background.
- In co-op, check that both players remain distinguishable and can read their own plasma, hits, and weapon fire during crowded formations.

## Decision

Record observations and any required fixes here after the hands-on sessions. Approve Phase 1 only after the solo and co-op checks pass; the visual production phase follows that approval.

## Alpha 9 balance verification — 2026-10-12

The approved balance profile is implemented. This record does not approve Alpha 9 or claim that its 5–8 minute difficulty target has been confirmed through human play.

Automated validation used Godot 4.7.2 headless with an isolated project copy under `.godot/alpha9_test_project`. It contains the current project/data/scenes/tests and imported cache, excludes the local `override.cfg` (which references an unavailable Godot AI addon), and uses `.godot/test_appdata` as `APPDATA` to avoid touching personal saves. The source override and normal save files were left unchanged.

| Check | Result |
| --- | --- |
| `tests/test_alpha_9_balance.gd` | PASS: 4,418 checks |
| `tests/player/test_fire_input.gd` | PASS, including the actual 0.20-second base interval |
| `tests/player/test_beam_effect.gd` | PASS |
| `tests/test_native_scale.gd` | PASS |
| `tests/test_enemy_feedback.gd` | FAIL: 34 animation-frame assertions, also reproduced with the previous gameplay scripts/resources |
| Main scene, 120 headless frames | Starts and exits; four ObjectDB instances and two resource references remain at exit, also reproduced with the previous gameplay scripts/resources |

The balance suite loads the real scenes after autoload initialization and checks all 18 waves, both run modes, all damage ranks and endless cycles 0, 1, 7 and 30. It verifies fractional damage, elite indicators, carrier/turret inheritance, density eligibility, gap-wall openings, actual formation and elite caps, reward roll boundaries, upgrade caps, rank-six extra side shots, capped-pickup score conversion, pooled projectile reset and retention of co-op difficulty after one death. It is not a human-input simulation, continuous 12-minute performance profile or visual readability verdict.

The feedback regression was adjusted to resolve turret enums from the runtime instance rather than compiling the gameplay class before autoload registration. Its remaining 34 failures are identical before and after this balancing change: mother-ship `explode` (6), and mounted-turret `aim_charge` (6), `aim_fire` (3), `aim_recover` (4), `ring_charge` (7), `ring_fire` (3), `ring_recover` (5). Concurrent headless runs also produced two transient flash-fade timing assertions; those did not reproduce in the isolated rerun. No animation assets or tracks were changed by this balance follow-up.

### Comparative playtests still required

- Compare the previous and new profiles on waves 1–3, 6, 9, 12, 15 and 18; use a fresh run when evaluating natural upgrade progression rather than advancing with debug controls.
- Complete at least three solo and three co-op sessions through 12 minutes or death, plus repeated finale cycles. Keep the renderer, input devices and player skill level consistent when comparing profiles.
- Include uneven pickup allocation and a partner death; the survivor must retain duo enemy health, density and caps.
- Record the following for each session and key wave:

| Session / profile | Mode / players | Time / wave | Build ranks per player | Common / heavy destruction time | Escaped targets / active heavies | Pickups / plasma use | Death cause / readability |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pending | | | | | | | |

Accept the profile only when small enemies feel responsive, collected upgrades noticeably improve clearing, waves 9–13 require deliberate placement and prioritization, and added density preserves readable projectiles, pickups and escape lanes. Check especially that unchanged heavy base health (36/48/12) does not create persistent accumulation with the stronger duo multiplier.

For every tuning change, record the observation, affected resource value, before/after result and targeted regression outcome here. Presentation failures and hands-on balance acceptance remain open release checks.

## Alpha 9 balance iteration 2 — 2026-10-12

Maintainer observation after playing the initial profile: the opening feels satisfactory, power-up progression is too fast, and higher-tier enemies need more health. This iteration supersedes the initial offensive rank targets and heavy base-health values recorded above.

| Parameter | Initial profile | Revised profile |
| --- | --- | --- |
| Damage upgrade | +0.25, 6 ranks | +0.15, 10 ranks; same 2.50 maximum damage |
| Fire-rate upgrade | -0.01 seconds, 7 ranks | -0.007 seconds, 10 ranks; same 0.13-second minimum |
| Side upgrade | +0.12 after unlock, 7 ranks; extra pair at rank 6 | +0.08 after unlock, 10 ranks; extra pair at rank 8; same maximum bonus |
| Interceptor base health | 6 | 8 |
| Standalone turret base health | 36 | 44 |
| Mother-ship base health | 48 | 60 |
| Mounted turret base health | 12 | 15; inherit the hull multiplier once |

Common health, density, co-op and wave/endless multipliers, elite multiplier, drop probabilities, upgrade weights and plasma parameters remain as in the initial profile. Keeping reward frequency preserves regular pickup feedback; smaller per-pickup gains delay offensive milestones. A solo common enemy now dies in one primary hit at damage rank seven instead of four. Maximum-power common clearing remains unchanged in both modes.

Automated balance regression: PASS, 5,576 checks, including the increased health matrix, ten-rank damage/fire-rate/side progression, mounted inheritance, pooled damage reset and actual three/five-projectile volleys at side ranks seven/eight.

Next hands-on comparison: opening waves should retain their feel; middle waves should offer longer build progression and more meaningful priority targets. Check that carrier/turret accumulation and the combined duo multiplier do not become excessive. Record useful-upgrade timestamps, heavy destruction times and plasma use before further tuning; no claim of confirmed difficulty or alpha release approval is made by this revision.

## Alpha 9 balance iteration 3 — 2026-10-12

Maintainer request: reduce power-up drop probabilities and player base health. Starting health is now three instead of four for each player, with the repair cap still at 12.

| Normal enemy | Previous power-up chance | Revised chance |
| --- | ---: | ---: |
| Drone | 13% | 9% |
| Fighter | 9% | 6% |
| Interceptor | 35% | 25% |
| Standalone turret | 41% | 29% |
| Mother ship | 45% | 32% |
| Mounted turret | 10% | 7% |
| Asteroid | 4% | 3% |
| Big asteroid | 10% | 7% |

Plasma probabilities and guaranteed elite power-ups remain unchanged. The exclusive normal reward roll allocates the removed power-up probability to no reward rather than to plasma. Offensive ranks, enemy health and wave density remain as in iteration 2.

Automated balance regression: PASS, 5,593 checks. The suite now checks all eight reward distributions over every possible roll, player initial health and death after three separate unprotected hits. Comparative human playtests remain pending; track whether reduced healing drops and starting health make the opening too punishing, particularly for the surviving co-op player.

## Alpha 9 balance iteration 4 — 2026-10-12

Maintainer observation: power-up drops remain too frequent and higher-tier enemies can withstand another health increase. This iteration makes a larger reduction to random upgrade supply while keeping common health, upgrade ranks, wave density, scaling and three starting player health unchanged.

| Enemy | Previous power-up chance | Current chance | Previous base health | Current base health |
| --- | ---: | ---: | ---: | ---: |
| Drone | 9% | 5% | 2 | 2 |
| Fighter | 6% | 3% | 2 | 2 |
| Interceptor | 25% | 12% | 8 | 10 |
| Standalone turret | 29% | 15% | 44 | 56 |
| Mother ship | 32% | 16% | 60 | 76 |
| Mounted turret | 7% | 3% | 15 | 19 |
| Asteroid | 3% | 1% | 2 | 2 |
| Big asteroid | 7% | 3% | 8 | 8 |

Plasma probabilities and guaranteed elite rewards remain unchanged; removed power-up probability becomes no reward. Mounted turrets continue to inherit the hull multiplier exactly once, with their base health at one quarter of the hull's.

Godot 4.7.2 headless balance regression: PASS, 5,593 checks, including the current health matrix, all eight exact reward distributions and solo/co-op/endless inheritance. Manual feel validation remains pending. During the next comparison, separate guaranteed elite pickups from normal random drops, measure the time to offensive milestones and check whether strengthened heavy targets accumulate faster than players can clear them, especially in co-op.
