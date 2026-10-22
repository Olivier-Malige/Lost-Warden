# Expanding impact-explosion correction

Implemented on 2026-10-22 against the maintainer-approved plan, after repeated feedback that the visible blast did not affect nearby enemies. This corrects step 11 only; step 13 ricochets remain pending. No commit, push or publication was requested.

## Approved behavior and implementation

- Preserve rank radii 24/30/36, damage 70/90/110% of the modified pre-critical base and the 0.30-second personal proc cooldown. Direct criticals do not multiply splash. Electric chains remain main-cannon-only.
- An accepted first impact defers creation of a service-owned wave. `PlayerHitEffects` owns one physics clock for its expanding damage disk and sprite frame. Radius starts at 25%, reaches 100% at 120ms, remains damaging through 160ms and leaves only visual debris until 320ms. These three durations are authored and validated in `UpgradeDefinition` / `impact_explosions.tres`.
- Requery actual overlapping collision shapes on every active physics tick. Enemies entering during the damaging interval can be hit, but sustained overlap and re-entry cannot repeat that wave's damage. The original impact position remains fixed after the enemy moves, dies or disappears. After 160ms the copied hit lease and origin collision exclusions are released; cooling visuals retain neither projectiles nor targets.
- Remove the four-target cap. `target_limit = 0` explicitly denotes unlimited overlapping blast groups, with resource validation rejecting a finite cap. Main/side cannon, missile, drone and satellite compatibility stays centralized and unchanged.
- Ordinary enemies and destructible asteroids are transparent to the blast's occlusion test. Explicitly armored surfaces still block it. Pre-exclude other overlapping ordinary hulls from each visibility ray to avoid repeatedly traversing the same formation; normal chain/missile targeting retains its existing visibility behavior. Physics acquisition is bounded to 512 surfaces, above the active encounter budget.
- Extend `resolve_hit` with an optional `channel` argument, default `root`, preserving existing callers. `visited_groups` returns independent chain/explosion exclusions for ordinary hulls, including shared directly hit groups and boss history. Each channel may damage an ordinary group once; chain and blast can stack in either order. Boss history remains global across all channels, preventing cannon/core multiplication and excluding an originating boss. Unknown channels and non-secondary attempts to use a secondary channel reject.
- Keep secondary damage non-critical and non-recursive. Every accepted blast victim receives the normal hull flash and a finite, owner-colored local impact through existing bounded combat feedback. Normal ownership, score, XP, plasma and elimination rewards remain intact.
- Visual capacity is independent of damage. Eight displayed waves and 64 local feedback instances are presentation caps; culled visuals never cancel a damaging wave. Pause freezes the service clock and cooldowns. DYING cancels pending, active and cooling waves for that owner; world teardown clears their roots, weak visual references and requests.

## Native presentation

The Aseprite MCP master retains eight 96x576 source frames, exported as 768x576 with six 96x96 cells per frame, pivot (48,48). P1 rank rows are 0-2, P2 rows 3-5. `detonate` covers frames 0-7 at 40ms; `active_wave` is 0-3 and `cooling_fragments` 4-7. The first four frames show radius fractions 25/50/75/100%; later frames use sparse dim fragments without a continuous bright ring. Separate layers keep active fronts and inactive remnants editable. No runtime sprite scaling or new audio is included.

The menus now say AREA and retain +25% / +50% rank-radius bonuses; the obsolete four-target claim is removed. Existing 64px cards and 16px miniatures remain otherwise unchanged.

Native captures in the ignored isolated project: `explosion_wave_{solo,coop,wide}_{000,040,080,120,160,240}.webp` and `explosion_wave_choices_{solo,coop,wide}.webp`. They show real six-enemy formations, actual enemy movement/health checks, both owners, the expanding front, local hull flashes and inactive debris. COLOR-FX, ICON-PIXEL-LOCK, LIGHT-HIT-FLASH, LIGHT-HIT-SCALE and COMP-SAFE-EDGE score 2/2 in the inspected states. These bounded sequences do not establish full-run balance or maximum-density performance acceptance.

## Actual verification

| Check | Result |
| --- | --- |
| Impact-explosion fixture | **263 native checks PASS**, clean console and exit |
| Moving formation | Six real Enemy scenes using their normal rectangle colliders and real straight-movement physics, including three hulls aligned behind each other on both sides: all six receive exactly one full blast amount |
| Timing | Initial quarter radius; synchronized 40/80/120/160ms frames and damage; entering, sustained overlap, leaving/re-entering, inactive late entry; fixed center after origin movement; root release before debris cleanup |
| Geometry | All rank boundaries, separated hulls, rotated/offset rectangle, enclosing hull and explicit armor occlusion |
| Synergy | Actual chain plus blast on one ordinary target in both resolution orders, per-channel repeat rejection, direct-origin exclusion; both channel orders against real overlapping boss surfaces still accept one boss hit |
| Sources | Real pooled main/side/missile/drone collisions and satellite contact, emission rank retention and cross-player projectile reuse |
| Lifecycle | Queued and active pause, owner death during active damage and during cooling, world cancellation, vanished origin, later direct contacts and repeated world teardown without node growth |
| Saturation | Twelve independent blasts still apply twelve full secondary amounts with only eight visible waves; all effects expire and repeated gameplay-driven waves return to the node baseline |
| Rewards | Secondary owner credit, normal XP/score/elimination and exactly one authored plasma cell, with no repeated kill rewards |
| Native regressions | Chains **200**, missiles **458**, escort drones **460**, selection **48**, progression activation **76**, all PASS with clean exits |
| Other affected regressions | Satellites **228**, accepted-hit **41**, offers **2,133**, boss parts **73**, all PASS |
| Art | All opaque pixels match Lost Warden 64 with binary alpha; eight frames at 40ms and the three tags match the source; fresh Aseprite composite/export audit reports zero differing visible pixels |
| Editor diagnostics | **87 game scripts + six combat fixtures, 93 diagnostic documents, zero errors/warnings** |

Tests use the isolated addon-free `.godot/phase_2_runtime_validation` project and task-local APPDATA. Native commands use `--rendering-method gl_compatibility --script res://tests/test_impact_explosions.gd`. Initial headless feedback assertions observed already-expired short-lived VFX; moving those observations into the active interval fixed the fixture without changing damage. A subsequently added test variable shadowed an inherited helper; it was renamed, with no warning suppression. Headless missile/escort runs retain the previously documented two-object/one-resource shutdown-retention warning; the cited native reruns are clean.

Human playtest of usefulness and feel remains pending. The requested correction is implemented locally, with no broader balance retuning, new weapon family or later roadmap step.
