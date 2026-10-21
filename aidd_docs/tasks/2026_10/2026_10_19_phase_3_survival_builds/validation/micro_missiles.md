# Autonomous micro-missiles — 2026-10-21

Step 8 delivered locally after the maintainer approved the described next checkpoint. Effect balancing remains deferred; no XP/encounter tuning is included. The family is available through ordinary offers and occupies one personal offensive slot, regardless of its three acquired ranks.

Latest playtest revision: missiles are smaller at rank one, grow through three native sprite sizes and launch 1/2/3 entries per volley. Missile hits retain criticals but cannot trigger lightning. This supersedes the initial one-size/one-projectile delivery and its missile/chain compatibility. The hard cap remains three active/reserved missiles per player; a volley uses only remaining free capacity and cannot create a backlog.

Forward-targeting follow-up: initial acquisition, guidance target retention and the one permitted reacquisition now require the target to lie in a 90-degree cone around screen-up, authored in the weapon resource. Side/rear enemies cannot outrank a farther valid forward enemy. A passed or lateral target is abandoned rather than causing a U-turn; any remaining reacquisition is forward-only. Cone filtering happens before logical-group reduction, preserving valid boss-surface selection. Non-missile targeting defaults to its existing unrestricted behavior.

## Runtime contract

| Rank | Authored damage | Base volley interval | Missiles per volley | Hull collision |
| --- | ---: | ---: | ---: | --- |
| 1 | 0.9 | 1.10 s | 1 small | 3x6 px at (0,-1) |
| 2 | 1.1 | 0.95 s | 2 medium | 4x8 px at (0,-2) |
| 3 | 1.3 | 0.80 s | 3 large | 5x10 px at (0,-3) |

DAMAGE multiplies the authored missile damage once, up to x2.25. FIRE_RATE multiplies the interval by `manual_delay / 0.20`, with minimum factor 0.6. These values are resources: `data/upgrades/micro_missiles.tres` references `data/weapons/micro_missile.tres`. No numerical balance acceptance is claimed.

PlayerWeapons advances autonomous readiness from the living player's normal physics update, independently of manual cannon/plasma input. Initial acquisition picks the nearest eligible visible target within 220 px of the muzzle; distance ties use stable combat identity. No target retains one ready opportunity. A saturated cap discards that opportunity and waits a normal interval, without a backlog burst. Each owner has at most three active plus reserved missiles.

The service reserves capacity and creates a copied direct MISSILE packet before deferred materialization, including the emitted rank. Criticals roll once at emission on the personal combat RNG. Missile snapshots discard piercing, ricochet and energy chains; an independent source-kind guard also blocks lightning even from a manually constructed missile packet carrying that modifier. A missile cannot consume the cannon's chain cooldown. Physical impacts have no intrinsic splash. Accepted kills retain normal player credit, XP/plasma rules and elimination counting. Each missile duplicates its collision shape so a larger rank cannot resize another flying missile; pool reuse restores the new owner's authored rank and footprint.

Actual flight starts upward at 240 px/s and turns by at most 240 degrees/s. A valid target remains attached until invalid; first loss permits one nearest visible reacquisition from the current position. A failed attempt or later loss leaves straight flight. Lifetime is 1.8 s; collision, expiry or screen exit returns the node through ProjectilePool. Owner DYING cancels pending/new emissions and new procs; existing missiles may finish their bounded flight/hits. World removal clears queued work. Reuse resets root/reservation, target, reacquisition latch, damage, owner art, heading, age and lifetime. Pause freezes emitter, guidance and lifetime.

## Art and presentation

Produced through the Aseprite MCP using Lost Warden 64. The source now has sixteen 16x48 frames and owner slices with pivot (8,12), exporting a 256x48 PNG/JSON sheet. Each 16x24 runtime cell uses P1 row y0-23 or P2 row y24-47. Tags `flight_small`, `flight_medium`, `flight_large` map to source frames 0-3, 4-7, 8-11 at 60 ms; `contact_impact` maps to 12-15 at 50 ms. P2 runtime frame indices add 16. Three hulls are redrawn on the native grid, with matching collision sizes above; no fractional image scaling. Decorative fins/exhaust stay outside the central hull collision. All four original impact frames are pixel-identical after remapping; impact sprites remain collider-free, 200 ms and globally capped at 24.

Card/miniature column 13 now shows three graded missile sizes, using editable layer `Ranked missile volleys`; columns 0-12 remain pixel-identical. Cards retain 896x128 dimensions, 64px cells at x832 and owner rows y0/y64. Miniatures retain 224x32 dimensions, 16px cells at x208 and rows y0/y16. The illustration keeps the real Nomad. Source/export equality, exact palette, binary alpha and preserved prior cells pass for all three pairs. The revised projectile source/export contains 1,172 opaque pixels across sixteen frames.

Reviewed native 640x400 captures in `.godot/phase_2_runtime_validation`: `micro_missiles_solo_1.webp`, `micro_missiles_coop_1.webp`, `micro_missiles_solo_choices.webp`, `micro_missiles_coop_choices.webp`, `micro_missiles_coop_impact_0.webp` and `_2.webp`. The fixture additionally saves three flight samples and all four impact frames in each mode. Flight captures use actual autonomous emission/physics; impact presentation places the still-flying missiles on targets to inspect real collision callbacks. Cards are controlled review offers rather than evidence of a natural random hand. Owner silhouettes, native sampling and card/HUD separation pass focused ICON-PIXEL-LOCK, LIGHT-PLAY-SEP and COMP-SAFE-EDGE at 2/2 in the inspected states. No broad visual/performance or human co-op balance certification is claimed.

## Focused verification

Godot 4.7.2, addon-free isolated runtime, separate APPDATA directories:

| Fixture | Result |
| --- | --- |
| `tests/player/test_micro_missiles.gd`, native compatibility renderer | **458 checks PASS** including real destroyed-target reacquisition, clean shutdown |
| Earlier headless missile fixture, before final extra cases/captures | **185 checks PASS** |
| `tests/test_upgrade_offers.gd`, headless | **2,133 checks PASS** |
| `tests/test_progression_activation.gd`, native | **76 checks PASS**, clean shutdown |
| Activation, headless | **67 checks PASS**, existing two-object/one-resource shutdown warning |
| `tests/test_energy_chains.gd`, headless | **132 checks PASS** |
| `tests/player/test_piercing_and_critical_hits.gd`, headless | **708 checks PASS** |
| `tests/player/test_beam_piercing.gd`, headless | **111 checks PASS**, two-object/one-resource shutdown warning observed |
| `tests/test_upgrade_selection.gd`, headless | **42 checks PASS**, same shutdown warning observed |
| `tests/player/test_player_hit_contract.gd`, headless | **41 checks PASS** |
| Aseprite parity, palette, alpha, durations and preserved icon cells | **PASS** |
| `git diff --check` | **PASS** |

Coverage includes all rank cadences, volley counts and DAMAGE/FIRE_RATE extremes, actual distance/turn changes, moved targets, lifetime, one-time reacquisition success/failure, range/ties, no-target readiness, independent partner caps, partial volleys under saturation, independent per-missile collision shapes, physical ordinary/armor/cannon contacts, critical damage with strict lightning exclusion, cross-player rank/size reuse, rewards, pause, manual cannon/plasma coexistence, death, cancellation and five real world-destruction cycles without node growth. A cannon still triggers lightning immediately after a missile hit. Twenty-four seeded missile critical emissions match an independent stream despite unrelated encounter/drop/offer draws. Latest focused regressions after this revision: offers **2,133**, chains **132**, progression **67** checks PASS; other regression rows above retain the initial checkpoint's results.

Native follow-up captures `micro_missiles_rank_1.webp` and `_3.webp` were inspected alongside updated co-op flight/cards. The fixture saves all three ranks and verifies their actual volley count. Native small/large silhouettes and their 1/3-projectile salves are distinct; focused ICON-PIXEL-LOCK and COMP-SAFE-EDGE remain 2/2 in these views. Palette/export checks find no colors outside Lost Warden 64.

Latest forward-only checks: **447 native missile**, **423 headless missile**, **132 headless chain** and **2,133 offer** checks PASS. The headless missile run retains the known two-object/one-resource shutdown warning; native exits cleanly. Added cases cover closer rear/lateral exclusion, readiness when only invalid angles remain, the exact 45-degree boundary, a target crossing behind, forward-only reacquisition and no second turn after a replacement is passed. The moved-target flight fixture now exercises an off-axis forward target. Native co-op flight was re-inspected; sprites and combat values are unchanged.

Actual destruction follow-up: the existing one-time reacquisition is confirmed through a real ranked volley and lethal physics callback, rather than only removing the original target node. One missile destroys the first enemy while it is still in its explosion state; both surviving missiles choose the nearest valid forward replacement, physically reach it and release their roots/reservations. Closer side/rear enemies remain untouched, and each missile spends its existing lifetime without a refresh. **458 native checks PASS**, clean shutdown. This request required regression coverage, not a runtime behavior or range change; the authored acquisition range remains 220 px and the forward-only rule is preserved.

The synthetic capacity fixture now uses only still-unimplemented effects; capped-offer activation caps micro-missiles before asserting that side-shot rank four is its sole remaining offer. Historical economy simulations were not rerun for the expanded fourteen-entry catalog. New dedicated audio, permanent progression, save-schema changes, commit/push and the escort drone are outside this delivery. Step-5 human observations and final economy/build/performance/audio acceptance remain pending.
