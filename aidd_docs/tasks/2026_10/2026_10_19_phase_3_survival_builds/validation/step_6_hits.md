# Step 6 — accepted hits and reproducible combat

Implemented and verified on 2026-10-20, Godot 4.7.2 official, Windows, addon-free isolated runtime. Native checks use OpenGL compatibility on the RTX 3060. Scope is the infrastructure of step 6; no new offensive family or card is enabled.

## Delivered behavior

- Enemies and boss surfaces expose `receive_player_hit`, returning true only for positive accepted life loss. Ownership is assigned before the existing virtual damage/kill path. Armor, destroyed targets, invalid amounts and entering/inactive bosses reject without false kill credit. Unrelated collision damage retains its existing entry point.
- Guns, signature plasma and shield-reflected projectiles use this boundary. Gun packets freeze owner, per-player source sequence, authored capped base, pre-critical damage, personal ranks and critical state at emission. Current packets remain non-critical. Plasma retains its separate base/overdrive calculation; reflections retain enemy-shot damage and take no new gun modifiers.
- World-owned `PlayerHitEffects` owns root leases, accepted logical groups and copied deferred requests. Boss core/cannons share one group across a root and its children. Rejected armor does not consume that group. First-impact opportunities are limited to direct gun roots with a living owner; secondary packets cannot create recursive requests or critical damage.
- Pending children reserve their capacity and root history before deferral. Their packets, impact position, velocity and bounded lifetime are copied, with no reference to a recyclable projectile. Owner eligibility and world generation are checked before materialization. DYING blocks new emissions and queued owner requests, while existing direct shots can finish. World cancellation clears all bookkeeping.
- Spawn identities are monotonic strings assigned without RNG draws. Mounted turrets and asteroid fragments derive stable identities from their parent and child index. Bosses and reinforcements receive explicit identities. Per-player combat RNG streams are derived from the run seed without changing the four existing streams.
- `CombatTargeting` filters living visible targets within the world and viewport, orders distance ties by authored identity, reduces logical damage groups and uses actual physics rays for line of sight. Pool lookup is scoped to the containing world, avoiding reuse from another still-present world.
- Projectile recycling clears snapshots, reservations, visited groups, penetration/steering state and lifetimes. Enemy-shot reuse restores its authored exclusion group and clears reflecting-player ownership. Parking and deferred child creation stay outside physics callbacks.

## Actual verification

Run suites with separate ignored APPDATA directories in `.godot/phase_2_runtime_validation/`:

```powershell
$godotExe = 'C:/godot/Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path .godot/phase_2_runtime_validation --script res://tests/player/test_combat_reproducibility.gd
& $godotExe --rendering-method gl_compatibility --path .godot/phase_2_runtime_validation --script res://tests/player/test_player_hit_contract.gd
```

| Suite | Result / evidence |
| --- | --- |
| Player hit contract | **41 headless / 42 native checks PASS**, clean final shutdown. Real gun/shield/secondary/overlapping-boss Area2D callbacks; emission snapshots; owner changes during flight; P1→P2 pool reuse; exact kill reward; armor/entry rejection; one boss group per root including a deferred child after root release; callback-time reservation and recycled-source independence; child expiry; DYING; stale generations. |
| Combat reproducibility | **1,641 checks PASS**, clean shutdown. Seeds 0/1/42/99, solo/co-op, repeated and with extra combat/cosmetic draws: 24 traces. Ordinary actors, explicit carrier mounts/fragments, boss and reinforcements, source sequences and four legacy RNG states repeat. Eight world-removal cycles, real unobstructed/blocked sight queries, stable distance ties and two concurrent world pools. |
| Alpha 9 balance | **130 checks PASS**. |
| Encounter spawning | **6,122 checks PASS**. |
| Boss destructible parts | **73 checks PASS**. |
| Boss attack patterns | **1,035 checks PASS**. |
| Beam impact | **18 checks PASS**. |
| Beam upgrades | **36 headless checks PASS**. |
| Shield throwback | **PASS**. |
| Fire input | **PASS**, isolated serial execution. |
| Upgrade offers | **1,957 checks PASS**; active catalog remains unchanged. |
| XP rewards | **2,526 checks PASS**. |
| Progression activation | **76 native checks PASS**, clean shutdown, fresh solo/co-op/plasma captures. Earlier headless run: 67 checks PASS with the previously observed shutdown retention. |
| Foundation collision alignment | **PASS**, `-- --foundation-only`; this does not claim the historical full enemy/retired-pickup suite passes. |
| Seeded human-run launcher | Seed 29 native `--smoke` **PASS**, clean shutdown. Its progression and hit services now both use the requested seed. |
| Economy compatibility subset | **160 checks PASS**, seed 0 in both modes/profiles twice. All four resulting per-seed traces match the archived step-5 baseline exactly, including encounters, spawns, choices, XP and legacy RNG states. The 100-seed full economy suite was not rerun for this infrastructure-only change. |

An initial fire-input run alongside other cold-start suites failed the five `all_fire` wall-time assertions; rerunning alone passed without changing that test or its input/cooldown logic. Keep this timing sensitivity visible. Early new-test shutdown retention was traced to the real shield WAV still playing at teardown; the hit fixture now clears both positional and non-positional audio streams because this suite measures collision/lifetime behavior, not listening. Final new headless/native suites exit cleanly. No physics-flush or stale-source errors occur in the passing callback fixtures. These selected results do not imply every repository test passes.

## Existing art compatibility

Git blob hashes of all three active editable masters and PNGs are unchanged against the published foundation:

| Master | Runtime export |
| --- | --- |
| `assets/sources/player/pulse_shot_primary_master.ase` | `assets/sprites/player/player_shot.png` |
| `assets/sources/player/pulse_shot_side_master.ase` | `assets/sprites/player/player_side_shot.png` |
| `assets/sources/player/plasma_beam_master.ase` | `assets/sprites/player/beam.png` |

Weapon resources, projectile/beam scene mappings, animation tier/ownership indices and collision footprints have no diff. Existing source/export parity evidence therefore remains applicable; no new export or artwork is claimed.

Fresh native activation captures were inspected at `.godot/phase_2_runtime_validation/phase3_playable_coop_projectiles.webp` and `phase3_playable_plasma_normal.webp`. Red/blue shot ownership, forward side-shot arrangement, crisp existing silhouettes and signature plasma remain visible with the same HUD separation. ICON-PIXEL-LOCK, LIGHT-PLAY-SEP and COMP-SAFE-EDGE score **2/2** for these captured states. This is compatibility evidence, not acceptance of the later offensive effects or new audio. The new hit suite also saves `phase3_hit_contract.webp` in the isolated runtime.

## Handoff

The maintainer explicitly authorized proceeding after publication while the remaining step-5 human observations stay deferred. [The first actual seed-69 log](step_5_solo_seed_69.json) records five choices, but two seeded observations and qualitative XP feedback remain pending. No XP threshold/reward revision or human co-op balance acceptance is implied.

Step 6 is complete. Stop here for review. Step 7 (piercing and critical hits plus their art) remains pending; no later offensive implementation was started.
