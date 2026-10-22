# Step 11 — impact explosions

**Current implementation:** the maintainer-approved [expanding-wave correction](impact_explosion_wave.md) supersedes the instant four-target checkpoint described below. It has 263 clean native checks; retained numerical tuning is unchanged. Earlier entries remain as delivery history.

Implemented and verified on 2026-10-21 with Godot 4.7.2, under the maintainer's explicit instruction to proceed. The satellite and explosion checkpoints remain local after published escort commit `f20c148`; no commit/push was requested for this step.

## Behavior

- Three ranks in one offensive slot: 24/30/36px radius and 70/90/110% modified pre-critical direct damage. A circular physics query selects actual overlapping collision shapes, with line of sight and stable ordering by visible surface distance then spawn identity. At most four additional logical groups receive damage.
- Only the first accepted compatible direct hit can trigger: main/side cannon, drone bolt, missile or satellite contact. Plasma, reflection and all secondary damage are excluded. Rejected surfaces do not consume an opportunity; denied cooldown attempts are discarded.
- Every compatible source shares its owner's 0.30-second cooldown, independent of FIRE_RATE. Each player owns an independent cooldown. Direct DAMAGE is already applied and is not compounded; a direct critical does not multiply splash.
- Before deferral, copy the hit amount, owner/source identity, center, rank, origin RIDs and visited groups. Retain only the immutable root packet/history, never a pooled projectile or target object. Resolve from the original center and union the captured groups with current root history. Chains resolve first, preserving their previous order; explosions skip their accepted groups. No secondary recursion is possible.
- Boss armor blocks rays. A boss-origin root excludes the entire boss; an external root can reach only one visible vulnerable boss surface. An initial target can disappear without invalidating the copied center. Later piercing contacts remain in root history and cannot be damaged twice.
- Secondary kills retain normal owner credit, score, XP, one elimination and authored plasma drops. Pause freezes queued work, cooldowns and animation. DYING cancels new owned requests; world teardown clears retained roots and generation state.
- Visuals are non-colliding, freshly instantiated eight-frame sprites at 40ms per frame (320ms total), max eight active globally. They expire rather than entering a pool, so no reused owner/rank/animation state exists. A visual cap cannot change already resolved damage. No VFX retains targets or roots.

## Verification

| Check | Actual result |
| --- | --- |
| Explosion fixture | **171 native checks PASS**, clean console/exit |
| Data/slots/ranks | Normal live acquisition, personal ranks, one slot, cap, invalid radius/cooldown/target data, card snapshots |
| Geometry/cap | All rank boundaries and outside neighbors, nearest four of six, deterministic equal-distance tie, occluding armor |
| Sources/damage | All direct and rejected kinds; real pooled gun/side/missile/drone collisions and real satellite overlap; maximum DAMAGE once; emission rank survives later upgrades; cross-owner shot reuse |
| Cooldown/critical | Shared source cooldown, max FIRE_RATE, both owners, exact boundary, discarded attempts, pre-critical splash and no recursive modifiers |
| Coexistence/rewards | Chain plus explosion root dedup, one boss group, secondary kill ownership/XP/score/elimination/plasma once |
| Lifecycle | Queued pause/resume, DYING, cancellation, vanished origin, later root contacts, three real world removals with pending work and stable node baseline |
| Visual lifecycle | Eight-instance cap, paused team/rank animation, finite expiry, three repeated stable node baselines |
| Native capture | Solo/co-op/wide, three ranks and both ownership rows, ignition/expansion/peak/decay, selection cards and personal miniatures |
| Regressions | Offers 2,133; accepted-hit 41; native chains 165; missiles 434; escorts 379; native satellites 269; native beam 118; native selection 48; native activation 76; native boss parts 73, all PASS |
| Editor diagnostics | 87 game scripts + six combat fixtures, 93 diagnostic documents, zero errors/warnings |
| Art | Aseprite MCP masters; all three source/export pairs have zero differing visible pixels; exact 64-color palette, binary alpha, previous visible atlas columns preserved |

Commands run against the isolated addon-free `.godot/phase_2_runtime_validation` project, using task-local APPDATA. Native runs use `--rendering-method gl_compatibility --script res://tests/test_impact_explosions.gd`. Initial headless checks passed; headless beam/selection/activation retained their pre-existing shutdown-retention warning and were rerun natively with clean exits. A temporary test reference to the PlasmaCell class exposed command-line autoload parse order; replacing that fixture check with the real scene path fixed the issue, and the final native run above is clean.

Native evidence in that ignored project: `explosions_{solo,coop,wide}_{0,2,3,6}.webp` and `explosions_choices_{solo,coop,wide}.webp`. Peak P2 positions were corrected in the fixture to keep all three radii inside the playfield; gameplay bounds are unchanged. At natural screen edges an impact effect may be clipped by the viewport, as expected for a fixed impact center.

## Presentation review and remaining acceptance

Inspected native frames show crisp local ignition, growth with rank and rapid fragment decay against the existing starfield. COLOR-FX, ICON-PIXEL-LOCK, ICON-META, LIGHT-HIT-FLASH, LIGHT-HIT-SCALE and COMP-SAFE-EDGE score 2/2 in the reviewed central states. Solo/co-op cards retain readable rank, radius, target cap, damage factor and cooldown. This is visual verification of bounded states, not full-run readability or performance acceptance under maximum density.

Effect balancing remains deferred. Dedicated audio remains with the maintainer; no new audio was added. Human playtest and final combined builds/economy/performance acceptance remain pending. Stop before step 13 ricochet shards.

## Playtest correction — 2026-10-22

Reproduced the reported reach problem with a radius-ten enemy hull: its near edge overlapped the blast while its center lay eight units outside the range. All three ranks failed the added test with center-based targeting. The corrected physics overlap passes all three ranks, an offset/rotated rectangle, a hull enclosing the impact origin, and separated-hull rejection. Radius increased to 32/40/48px; damage factors, four-group cap, armor/visibility rules and cooldown are unchanged. Percent-only card checks verify base blast / +25% / +50% radius relative to rank one and no PX label.

The apparent unintended lightning path was the still-enabled satellite chain permission. Explosion secondary damage already could not recursively trigger chains; ordinary cannon hits can still independently trigger both equipped families. The source/modifier allowlist now lives in PlayerHitSnapshot, strips unsupported snapshot modifiers and guards both proc queues. Raw/unfiltered sources and future-source/effect rejection are covered. Main/side cannon chains remain valid; missile/drone/satellite contacts do not emit lightning or consume its cooldown. No additional per-weapon exclusions are required.

Final native results: **168 explosion**, **165 chain**, **269 satellite**, **48 selection**, **76 progression activation** checks, all clean. Headless affected regressions: missiles **434**, escorts **379**, accepted-hit **41**, offers **2,133**, boss parts **73**, all clean. Fresh editor diagnostics: **93 documents / zero issues**. Expanded Aseprite/PNG art uses 96px cells and remains pixel-identical, palette-exact and binary-alpha. The captures named above were refreshed. Human effectiveness/readability acceptance remains pending; no commit/push or later phase is included.

## Final concentrated-blast tuning — 2026-10-22

The maintainer requested smaller radii with significantly stronger damage. Each radius is 25% lower (24/30/36 instead of 32/40/48) and each damage factor is doubled (70/90/110% instead of 35/45/55%). Explicit data assertions and actual primary/side/missile/drone projectile collisions verify those values once, including critical-base isolation, satellite overlap, cooldowns, armor, cap, rewards and boss groups. Percentage radius bonuses are unchanged. Art is rebaked through Aseprite MCP and inspected at native scale; parity, exact palette, binary alpha and frame mapping pass.

**171 native explosion checks PASS**, clean console/exit; **200 native chain checks PASS** now include both owners and side-shot ranks 1/4 with all four actual inner/outer bolts. Side hits cannot consume the main chain cooldown; the main shot still triggers immediately afterward. Selection **48** and activation **76** native checks, plus headless satellites **228**, missiles **434**, escorts **379**, accepted-hit **41**, offers **2,133** and boss parts **73** pass. Editor diagnostics cover 93 documents with zero issues. No commit/push or later step is included.
