# Step 14 verification checkpoint — 2026-10-29

Status: **in progress; economy decision and remaining verification pending**.

The maintainer accepted returning ricochets and requested a local commit followed by the next roadmap step. Ricochet checkpoint: `a4108bb` (`feat(combat): add returning ricochet shards`). No push was requested. Separate selection-music work and the local MCP settings are intentionally outside that commit.

## Current contract and isolated execution

The current catalog has 21 entries: nine offensive families, ten utility families, energy recovery and score fallback. Legal builds have three offensive and three utility families, yielding 84 offensive triples, 120 utility triples and 10,080 maximal cross-product builds. This supersedes step 14's historical four-offensive/eight-family/one-drone references. Rank-three escort support contains two drones; orbiting satellites remain three at every rank. Existing ricochet and defensive revisions retain precedence over historical contracts.

Execution uses a copied, addon-free project at `.godot/phase3_final`, Godot 4.7.2, separate APPDATA/LOCALAPPDATA and separate saves. Runtime/data/assets/tests are copied from the current checkout, including the separately supplied selection music. No personal records or root project resources are modified by these fixtures. The host reports a root-certificate-store startup warning.

## Legal-build and lifecycle coverage

`tests/test_phase_3_builds.gd`: **938,786 checks, zero failures**, across all 10,080 maximal builds. Every authored rank is acquired through the real PlayerLoadout eligibility path. Checks cover full category capacity, maximum-rank rejection, unowned-family rejection, healthy max-build fallback, seeded offers, source/modifier filtering, reset and immutable snapshots. This is exhaustive data/eligibility coverage, not 10,080 actual combat runs or a performance benchmark.

| Current isolated suite | Checks | Failures |
| --- | ---: | ---: |
| Run progression | 102 | 0 |
| Upgrade offers | 4,923 | 0 |
| Live progression activation | 71 | 0 |
| Upgrade selection | 79 | 0 |
| Selection audio/presentation | 25 | 0 |
| Debug level-up | 44 | 0 |
| XP orbs | 30 | 0 |
| XP rewards | 2,526 | 0 |

The debug-level fixture passes its assertions but reports five retained ObjectDB instances and one resource on shutdown. This is recorded as an outstanding diagnostic, not hidden by the exit status. These passing suites do not establish a blanket repository pass. They complement the ricochet checkpoint's 200 headless / 202 native physical-hit checks and its 188 chain / 203 explosion / 41 hit-contract regressions.

## Economy measurement

The existing version-one `tests/test_xp_economy.gd` was replayed unchanged with the complete current catalog. It measured seeds 0-99 in solo/co-op, perfect collection/miss-every-fifth, with two repeats: 800 five-minute virtual runs. The exact scripted kill/collection policy and its limitations remain those in [step 5 evidence](step_5_economy.md#reproducible-fixture). It does not measure actual player collection, build-dependent kill speed or native performance. Completed results and raw evidence are recorded below.

## Remaining acceptance and practical limits

- The maintainer explicitly accepts the current XP cadence provisionally. Two seeded solo observations and qualitative feedback remain pending; automated projections do not replace them.
- The four reference-build comparisons and five-minute native samples per mode are now measured below. They establish behavior under declared test conditions, not universal build balance, mathematical worst-case performance or natural survival difficulty.
- Solo frame-time spikes remain a performance observation requiring a controlled follow-up before a smoothness claim. Different-day solo/co-op measurements must not be interpreted as a scaling benchmark.
- Full current-catalog card/icon/slot geometry is now checked in 28 normal/wide solo/co-op layouts. Native effect/boss captures and prior focused source/export evidence complement this; no blanket claim that every repository suite passes is made.
- Selection music is integrated separately; final listening/loop-boundary approval and any missing-cue deferral remain human decisions. Shutdown ObjectDB/resource warnings remain recorded.
- Phase 3 is not marked complete and Phase 4 is not started. No economy, enemy-pressure, health, combat-rank or slot tuning is included. Step 14 remains in progress until its remaining human and performance acceptance items are resolved.

Additional isolated combat regressions: destructible boss parts 73 checks, boss patterns 1,035 checks, natural boss approach 18 checks and elites 3,280 checks; all assertions pass. These use the current copied catalog and existing encounter data without tuning.

## Full-catalog economy result and maintainer decision

The unchanged version-one fixture completes **800 simulations / 16,324 checks, zero failures**, covering 400 unique mode/profile/seed combinations, each repeated twice. [Summary](step_14_economy_summary.json) and [complete compressed traces](step_14_economy.json.gz) retain actual data with closed XP accounting and deterministic repeats. The results reproduce the earlier cadence despite the expanded catalog.

| Mode / collection profile | First choice | Interval 1 | Interval 2 | Interval 3 | Interval 4 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Solo / perfect | 23.00 | 21.73 | 26.47 | 33.07 | 35.50 |
| Solo / miss every fifth | 26.38 | 27.92 | 33.22 | 38.38 | 38.17 |
| Co-op / perfect | 20.87 | 19.03 | 23.82 | 27.87 | 32.53 |
| Co-op / miss every fifth | 23.07 | 24.38 | 27.50 | 33.97 | 35.73 |

Times are median gameplay seconds, not observed human performance. Per-run emitted/collected/lost/active XP is preserved in the raw traces and per-profile averages in the summary. The first-choice goal is 20-25 seconds; early-interval goals were 35-50 seconds, which these projections do not meet consistently.

After reviewing the refreshed evidence, the maintainer explicitly chose **"Conserver le rythme actuel pour l'instant"** on 2026-10-29. This authorizes continued step 14 verification against the current provisional cadence. It does not change any threshold, reward, encounter pressure, combat stat or slot count and does not fabricate the two remaining solo observations or final balance acceptance. Native stress/build/presentation work therefore continues; the economy mismatch remains visible as a provisional design decision.

## Native stress protocol

`tests/test_phase_3_lifecycle.gd` rotates four legal maximum-rank offensive triples (precision, propagation, autonomous, proximity), with identical damage/fire-rate/magnet utilities. Each mode runs for 300 actual wall-clock seconds at native 640x400, Compatibility renderer, VSync disabled and a 120 FPS cap, sequentially on the same workstation. Player collisions are disabled and energy is maintained for repeatability; movement/fire are scripted. Production enemy scheduling is retained, except one explicitly triggered boss. Test-only boss HP is held during the first and second phases, then defeat is scripted at 70% of the window to include recovery. This is a bounded technical stress sample, not a natural survival or difficulty run, and does not establish the mathematically worst possible loadout among all 10,080 legal builds.

The probe records every rendered wall-frame interval and one-second object/reservation/pool/XP snapshots. It checks owner caps (three missiles, six escort bolts, four shards, two drones, three orbiters), 128 XP active/reserved and legal slots, then performs five fresh world/teardown cycles. Counters and sorted p50/p95/p99 are saved independently per mode. No accelerated economy FPS is substituted for native frame time. Short initial harness smoke runs and discarded setup runs are excluded from final statistics.

A palette audit found two non-palette colors confined to the new ricochet card (242 pixels), now mapped to existing Lost Warden 64 metal shades. The editable source and export remain equal, and all twenty previous atlas columns are unchanged. The audit also detects preexisting colors `ffbc42`/`fff1b9` elsewhere in the card atlas and `ffbc42` in the miniature atlas; these baseline exceptions are recorded rather than silently recoloring previously accepted art.

## Solo native stress result

Completed 300.007 wall seconds on NVIDIA GeForce RTX 3060 / gl_compatibility at 640x400, 120 FPS cap and VSync off.

| Wall-frame milliseconds | p50 | p95 | p99 |
| --- | ---: | ---: | ---: |
| Solo | 8.853 | 27.894 | 47.714 |

Observed peaks: {"bolts":6,"missiles":3,"nodes":1184,"parked":165,"requests":1,"roots":28,"shards":1,"xp":5}.

Five post-teardown node baselines: 3, 3, 3, 3, 3. All cap and teardown assertions pass. Both phases exercised rings, aimed fire, spirals and drones; phase two also exercised the beam, followed by scripted defeat and recovery.

The p95/p99 reveal frame-time spikes on this workstation. No frame-budget optimization or universal smoothness claim is made. Four legal max-rank reference builds were sampled, not every possible loadout. Four shards and 128 orbs are asserted ceilings; this run did not saturate either ceiling. Full raw samples: [solo stress](step_14_stress_solo.json).

## Reference build comparison

The actual pooled-projectile/collision fixture completes **48 cases / 1,212 checks, zero failures**. Four legal offensive triples share max damage/fire-rate/magnet utilities. Seeds 0, 29 and 69 use identical instrumented stationary real drones: one 20-HP target or nine 6-HP targets on a 28px grid. Player positions are fixed at (320,350) or (320,215). The main cannon fires whenever ready; supports use their actual targeting, collision and cooldown paths. Targets do not attack or move. Physics is accelerated eightfold with 480 ticks per wall second, retaining a 1/60 gameplay-second step. These are technical target fixtures, not natural encounter or survivability results.

| Build / layout / distance | Cleared by 8 s | Median clear time among completed samples | Mean targets damaged by 2 s or completion |
| --- | ---: | ---: | ---: |
| autonomous, cluster, close | 3/3 | 1.37 s | 9 |
| autonomous, cluster, ranged | 0/3 | not reached | 8 |
| autonomous, focused, close | 3/3 | 0.27 s | 1 |
| autonomous, focused, ranged | 3/3 | 0.82 s | 1 |
| precision, cluster, close | 2/3 | 2.2 s | 9 |
| precision, cluster, ranged | 3/3 | 1.42 s | 9 |
| precision, focused, close | 3/3 | 0.18 s | 1 |
| precision, focused, ranged | 3/3 | 0.7 s | 1 |
| propagation, cluster, close | 3/3 | 1 s | 9 |
| propagation, cluster, ranged | 3/3 | 1.12 s | 9 |
| propagation, focused, close | 3/3 | 1.42 s | 1 |
| propagation, focused, ranged | 3/3 | 1.65 s | 1 |
| proximity, cluster, close | 3/3 | 0.8 s | 9 |
| proximity, cluster, ranged | 0/3 | not reached | 9 |
| proximity, focused, close | 3/3 | 0.72 s | 1 |
| proximity, focused, ranged | 3/3 | 1.67 s | 1 |

Uncleared samples are right-censored at eight gameplay seconds and remain in the raw [combat evidence](step_14_combat.json); completed-sample medians are explicitly labeled rather than presenting dropped failures as full clears. Precision has the strongest isolated-target result here, while propagation clears the ranged cluster faster. Proximity clears the close cluster fastest but cannot clear the ranged cluster in the window. Autonomous supports clear the close cluster but their acquisition limits leave distant corners alive. This establishes a measured strength and tradeoff per reference build under these specific fixtures; all builds still fire the main cannon and no claim about automatic-only play or human damage exposure is inferred.

## Resumption and presentation correction — 2026-10-30

The initial co-op stress process stopped before its 300-second window completed; no partial numbers are retained as a five-minute result. The complete co-op measurement is restarted. The solo result above remains valid. Reference combat completed all 48 cases / 1,212 checks with no failures.

The full-catalog presentation fixture initially found 120 label-rectangle overflows across 28 normal/wide solo/co-op layouts. The text often looked correct, but labels retained the default theme's larger minimum rectangles (for example 49px high for a two-line effect box) because text and size were assigned before the label entered the tree. The fix adds the label with its intended font overrides first, then assigns text and final geometry after the theme cache is available. A focused three-card smoke moves from three geometry failures to 58 passing assertions. Full native revalidation follows; no gameplay, input timing or audio behavior is changed by this correction.

## Co-op native stress result — 2026-10-30

Completed 300.002 wall seconds. Median/p95/p99 wall-frame time: 8.177 / 9.58 / 9.979 ms. All cap, boss-cycle and teardown assertions pass.

Observed peaks: {"bolts":6,"missiles":3,"nodes":1543,"parked":203,"requests":2,"roots":54,"shards":1,"xp":5}. Post-teardown nodes: 3, 3, 3, 3, 3.

Raw one-second counters and machine settings are in [co-op stress](step_14_stress_coop.json). The earlier solo run was measured on 2026-10-29 and the resumed co-op run on 2026-10-30. Hardware, renderer, resolution and frame-cap settings match; background desktop/workstation conditions were not controlled. Their large timing difference must not be presented as evidence that co-op is intrinsically faster. The solo spikes remain an observed performance concern.

## Final catalog presentation check — 2026-10-30

The corrected native fixture completes **28 layouts / 2,312 checks, zero assertion failures**. All twenty selectable upgrades are rendered at their final offered rank in legal personal six-family builds, in solo/co-op and at 640x400 / 800x400. Checks cover category text, parent/card/label rectangles, visible team illustrations and native capture saving. Score fallback is deliberately excluded because it is automatic, not a selectable card. Both owner rows of the final guard/ricochet cards were inspected in normal and wide captures; captures for every batch remain in the isolated user-data directory as `phase3_cards_<mode>_<width>_<batch>.png`.

After the label fix, upgrade selection passes 79 headless checks and selection-audio presentation passes 25. Native catalog and headless selection runs retain the known two-object/one-resource MP3 shutdown warning; assertion success does not hide that diagnostic. The isolated audio-only suite exits without that warning.

The ricochet composition layer also passes a direct Lost Warden 64 membership audit (zero off-palette opaque pixels). No existing card column was recolored.

Final native regressions after the label correction: beam capacity/recharge/HUD/choice presentation 38 checks, physical beam impact 18 checks, defensive pack 361 checks and debug inspector 71 checks, all with zero failures. Screen fades also exit successfully. The native beam-upgrade capture/HUD fixtures preserve the manual plasma signature and personal reserve behavior. These are scoped regressions, not a claim of a full repository pass.
