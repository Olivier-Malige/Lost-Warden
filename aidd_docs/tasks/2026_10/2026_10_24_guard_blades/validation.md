# Guard blades implementation evidence

Verified locally on 2026-10-24 with Godot 4.7.2 and native OpenGL Compatibility rendering on the RTX 3060. Scope is the maintainer-approved guard-blade family, followed by playtest before ricochet. No commit or publication requested.

## Delivered behavior

`guard_blades` appends effect ordinal 21 and is the twentieth live catalog entry. Three offensive and three utility slots are unchanged. Both blades share a single SECONDARY accepted-hit root, so an ordinary hull or logical boss group takes one impact per salvo. Authored damage 2/3/4 receives common DAMAGE once, without crits, random critical rolls, chains, explosions or ricochet. Enemy feedback remains local and contains no damage numbers.

The native annular field now uses inner radius 16, outer rank radii 60/72/84 and width 40 degrees, following the maintainer's successive size and progression feedback (original outer radius: 44). Left center sweeps -160 to -90, right -20 to -90, over 160ms, then holds the bright active overlap for 120ms; inactive fragments end at 400ms. Both arcs finish together screen-up after the 2026-10-25 convergence revisions. Both sprites follow the player's position and keep screen-up orientation. Real collision queries cover the traveled angles and short translations with convex sector strips (at most five degrees per strip, four units between translation subdivisions). Contact points come from actual transformed shapes, including offsets/rotation, before explicit-armor occlusion checks. Ordinary hulls do not block the attack. Already accepted groups are skipped before further contact/occlusion work.

Hostile projectiles touched by the active sweep are retired through ProjectilePool and marked immediately to prevent duplicate co-op clearing. Reflected shots, ally fire, rear shots and continuous beam nodes survive. Inactive tails neither damage nor clear shots. Owner death during accepted-hit callbacks cancels the remaining work and releases the root before further damage or feedback.

First activation follows a 0.6-second anticipation after gameplay resumes from acquisition. A tiny team-colored bar fills above the ship during this warning and before subsequent salvos, without text or numeric time. Recurring intervals are start-to-start 3/2/1.5 seconds, independent of FIRE_RATE and target presence; the warning is included in them. Rank changes preserve the remaining cooldown percentage (or initial warning time); the ongoing salvo retains its initial rank/damage/radius/native art. Long ticks emit at most one new salvo rather than accumulating missed work. Pause freezes every timer and visual. PlayerWeapons owns the controller and removes it safely on death; world teardown releases roots and weak service references.

The full debug snapshot includes rank, interval, remaining cooldown, salvo age/count and active state. The inspector shows the new state. An empty `SalvoAudio` node on Sounds is ready for a supplied sound; it does not delay or gate an attack.

## Original art and interfaces

All production artwork was authored/exported through MCP Aseprite using Lost Warden 64 and binary alpha:

- `assets/sources/player/weapons/guard_blades.aseprite`: ten 40ms frames on a 192x1152 canvas, six native 192px rank/team cells with pivot (96,96). Tags `active_blade` 0-6 and `inactive_fragments` 7-9; separate active-field/cooling layers. The matching PNG/JSON is 1920x1152. Runtime rotates two copies continuously from the physical age and selects the salvo's rank row; the second blade mirrors the decorative trailing detail. Native rank variants keep the inner gap fixed while extending the outer edge.
- Existing editable card/miniature masters append column 19, giving twenty columns: cards 1280x128, miniatures 320x32. The new layer `Guard blade forward sweep` shows Nomad and the two forward blades in both team palettes. All nineteen incoming columns remain pixel-identical.
- Cards display two blades, shot clearing, authored damage and interval, without pixel units. Existing HUD/build events show the new miniature in an ordinary offensive slot.

All three visible source/export composites match, exported pixels use only the canonical palette, and alpha is binary. A native engine audit confirms all three imported textures match the visible exported pixels, so stale import caches are excluded.

## Initial full-feature verification

| Native fixture | Checks | Result |
| --- | ---: | --- |
| Guard blades | 228 | PASS |
| Upgrade offers, including all 56 offensive triples | 3,781 | PASS |
| Defensive pack | 292 | PASS |
| Expanding explosions | 263 | PASS |
| Orbiting satellites | 364 | PASS |
| Progression activation / HUD | 80 | PASS |
| Upgrade selection | 51 | PASS |
| Accepted-hit contract | 42 | PASS |
| Electric chains | 200 | PASS |
| Continuous boss beam damage | 22 | PASS |
| **Total** | **5,323** | **Zero failures; clean native logs** |
| Runtime texture audit | 3 pairs | PASS |
| Fresh GDScript language-server diagnostics | 90 game scripts + 16 fixtures | 106 documents, zero errors/warnings |
| Source/export/palette/alpha and existing columns | 3 pairs | PASS |
| git diff --check | — | PASS |

The dedicated fixture measures actual HP for all ranks, six covered targets, double-blade overlap, exit/reentry and late entry, rear/inner/outer rejection, partial hull coverage, offset rotated shapes and player translation. It checks actual clearing/pool reuse, armor blocking both effects, logical boss exclusion, real asteroid damage, immediate acquisition/targetless cadence, rank snapshot/cooldown progress, pause, independent co-op ownership, death during a damage callback and repeated world restarts. Synergy tests fill legal offensive slots with criticals plus explosion/chain, verify common DAMAGE once and unchanged critical RNG, and ensure the fourth offensive/debug overflow is rejected.

The native dense case reaches all 24 hulls and clears all 24 covered shots without a victim cap. Median active step time is 509 microseconds, maximum 2,311 microseconds in the final run; these are bounded fixture measurements, not a full-run FPS guarantee. Long combined-build profiling remains in Phase 3's final acceptance.

Native captures `guard_blades_native_00..09.webp` show actual per-rank HP and both team effects. Solo/co-op/wide `guard_blades_{layout}_{hud,choices}.webp` show ordinary build slots and matching cards. Active/cooling frames, co-op choices and solo HUD were inspected. The optional cropped GIF in `.godot/guard_blades_qa/guard_blades_preview.gif` slows captured frames by two for effect inspection; its loop is not a cadence measurement.

Logs/art audits are ignored under `.godot/guard_blades_qa/`; fresh diagnostics are `.godot/console_qa/guard_diagnostics.json`. Existing historical collision-sweep failures documented in the contact-reliability checkpoint are outside this change and are not claimed resolved. Stop for maintainer playtest before ricochet; balancing and supplied audio remain deferred.

## Playtest size revision — 2026-10-24

The maintainer found the original blades too small to play comfortably. Outer reach increases from 44 to 60 at all three ranks (+36.4%); the inner gap remains 16. Damage, cadence, angular sweep and active/cooling durations remain unchanged. MCP Aseprite redraws both team fields and cooling fragments inside the existing native 128px cells, without runtime texture scaling. The guard card/miniature composition is adjusted to fit, preserving the nineteen other illustrations exactly.

Fresh native verification passes **240 checks**, including three additional hulls at radius 54 per rank, three hostile shots at radius 54, partial coverage at the new boundary, and rejection beyond it. Existing deduplication, armor, boss, pause, rank, co-op and lifecycle scenarios still pass. The dense case measures a 502us median and 2,100us maximum active step in this run. Fresh dual-team native captures show measured HP at radius 54 and the larger sweep; solo/co-op/wide menus are captured again. Exact Aseprite source/export palette/alpha/tag audits and three engine-imported texture comparisons pass. `git diff --check` passes. The combined suite and 106-document diagnostics above describe the earlier full feature verification; this scoped data/art revision reruns the dedicated fixture and asset checks.

## Rank progression and warning bar — 2026-10-24

The maintainer accepts base reach 60 and requests larger areas with upgrades, shorter proc delays and anticipation. Current outer radii are **60/72/84** (+0/+20/+40% reach); intervals are **3/2/1.5 seconds**. Damage remains 2/3/4, the inner gap 16 and the sweep 280ms active/400ms visual. Every salvo is preceded by a small team-colored filling bar above the ship during its final 0.6 seconds. As requested in the follow-up, it displays no text or numeric time. The first warning lasts 0.6 seconds after acquisition/resumption; recurring warnings do not add delay. Rank changes preserve the initial warning time or the recurring cooldown percentage. A salvo already underway retains its original damage, collision reach and native rank row.

MCP Aseprite supplies separate native rank/team variants on 192px cells, avoiding a stretched central gap or clipped rank-three edge. Cards report reach bonuses as percentages, plus actual damage and interval. All nineteen previous icon columns remain unchanged.

Final fresh native results: **280 guard checks**, **3,781 offer checks** and **51 selection checks**, all passing with clean exits. Guard coverage includes victims/projectiles near every rank's new boundary, exclusion beyond each rank, old/new radius and art across an in-flight upgrade, initial and recurring warning boundaries, pause, no damage/clearing during anticipation and no additional recurring delay. Existing armor, logical boss, co-op, death and teardown tests pass. Dense sweep median/max are 514/1,132us in the final bar-only run. Fresh diagnostics cover **106 documents with zero issues**. Exact source/export palette, binary alpha and animation tags, all nineteen older columns and **three runtime texture comparisons** pass; `git diff --check` passes. Native bar-only captures `guard_blades_warning_{06,03}.webp`, dual-color rank-one/rank-three sequences and updated co-op cards were inspected. Evidence logs are `bar_final.log`, `ranks_offers.log` and `ranks_selection.log` under the ignored QA directory. Stop for the next maintainer playtest; no ricochet, commit or push.

## Symmetric convergence — 2026-10-25

The maintainer requests equal overlap where the arcs meet. Both centers now end at -90 degrees instead of crossing to -70/-110: each moves 70 degrees toward the same forward orientation, using the existing shared physical clock for visuals and collision queries. Radii, damage, cadence, warning bar and active/cooling durations stay unchanged. The front still receives coverage from the two combined sectors; targets in their common passage still take one hit per salvo.

The refreshed native fixture passes **286 checks with zero failures**, including six new rank-wide checks for equal final rotation, center and animation frame. The overlap-window assertion now samples 210ms rather than 180ms, accounting for the arcs' reduced angular travel at the same total duration. Measured HP, projectile clearing, geometry, boss, pause, rank and lifecycle checks pass. Native frames 06/07 for both team colors were inspected at convergence/cooling; `git diff --check` passes. The final log is `.godot/guard_blades_qa/convergence_final.log`; dense-step median/max are 483/805us in this bounded fixture. The previous offer, art and language-server results remain the earlier revision's evidence, not newly rerun checks. Stop for playtest before ricochet.

## Visible overlap correction — 2026-10-25

The maintainer could not see the endpoint-only adjustment. Inspection shows why: full alignment previously happened at 280ms, exactly when the active edge disappeared. Motion now ends at **160ms**, leaving a **120ms bright, active hold** before the existing 120ms inactive tail. `sweep_motion_duration` is authored independently from the active lifetime and validated as positive, finite and shorter than it. Collision sampling uses that same motion duration and continues checking entering hulls/shots during the hold.

MCP Aseprite redraws frames 4-6 as a shared terminal edge, removing lateral trails; inactive frames 7-9 fade within the merged silhouette. Right-hand mirroring ends at convergence, so both held sprites have the same image, frame and transform instead of two mirrored decorations. No extra damage or effects occur; rank radii, damage, cadence, warning and total active/visual lifetimes remain unchanged. UI art is untouched in visible pixels.

Fresh results: **300 native guard checks and 3,781 native offer checks pass**, with clean game exits. Coverage includes a still-active exact overlap at all ranks, transformed sprite equality through the hold, enemies and projectiles entering during the hold, deduplication and invalid motion durations. Dense-step median/max are 491/973us. Fresh GDScript diagnostics cover **106 documents with zero issues**. Palette, binary alpha, source/export parity, tags, nineteen previous icon columns and three runtime texture comparisons pass; `git diff --check` passes. Native frames 04/06 show the held bright form; frame 07 shows narrow inactive cooling. The ignored preview `.godot/guard_blades_qa/guard_blades_meeting_comparison.gif` compares native before/after captures at 40ms/frame with a pause at the loop end. Logs are `merge.log` and `merge_offers.log`. Stop for playtest before ricochet; no commit or push.
