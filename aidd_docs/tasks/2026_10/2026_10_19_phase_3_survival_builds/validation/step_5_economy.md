# Step 5 — collected XP economy measurement

Date: 2026-10-20. Status: **measurement passed; maintainer chose to test the current cadence first; human acceptance pending**.

The playable foundation was committed and rebased on the freshly pulled `origin/master` (`0240d19`). This repository has no `main` branch. The sixteen rebased patches are unchanged according to `git range-diff`; the foundation commit is now `37c55d8`.

## Reproducible fixture

`tests/test_xp_economy.gd`, fixture version **1**, exercises the shipped encounter director/spawner, enemy XP/plasma roll order, `RunProgression`, `UpgradeTable` and personal `PlayerLoadout` rules. Seeds **0-99**, solo/co-op, perfect collection/miss-every-fifth, **two complete repetitions**: **800 runs**, each **18,000 virtual ticks at 1/60 s**, stopping at 300 simulation seconds. Result: **16,324 checks, zero failures**, equal repeated traces, 361.182 seconds wall time.

Runtime: Godot **4.7.2-stable official**, headless, Windows NT 10.0.26300 AMD64; addon-free `.godot/phase_2_runtime_validation/` project with repository junctions and isolated `qa_phase3_economy` APPDATA. Native launcher smoke used OpenGL compatibility on NVIDIA RTX 3060 and exited cleanly.

This is an **economic projection**, not observed player behavior, a physics test, a performance benchmark or a model of build-dependent kill rates:

- Each run starts with fresh personal loadouts/vitals; players are modeled as stationary and invulnerable. Combatants remain at their materialization positions and are scripted to die exactly 60 ticks later, irrespective of health or weapons. Mounted targets resolve before their hull; real debris construction, fragment reward exclusion, reservations/caps and authored explosion-body retention are retained.
- Test-only dispatch replaces deferred materialization outside engine physics callbacks. Production scheduling and gameplay RNG streams are used. The asteroid adapter suppresses random cosmetic frame selection. Combat timers, attacks, physics and audiovisual effects do not advance. Deferred queues flush between batches, never once per virtual tick.
- Positive XP events receive stable sequences. Scripted collection occurs 120 ticks after emission; every fifth event is missed in the second profile. Missed orbs never acquire a target. Their off-screen lifetime is sampled from the actual orb script at its starting height and cached (its `height + 16` retirement check; render-notifier callbacks do not advance in this projection). This schedule deliberately does not model real steering, attraction upgrades or homing success.
- The viewport is fixed to the authored 640x400. World marker positions are read from the actual scene. Peak entries stay below the real 128-entry pool cap, so overflow merging is not needed in these projections.
- Personal policy: `side_shot`, `damage`, `fire_rate`, `speed`, `orb_magnet`, `energy`, `shield`, then the lexicographically first offered ID. Actual P1/P2 offer drawing, eligibility, slot limits and vital reward updates apply; only genuinely empty offers allow the 500-score fallback. Choices consume zero gameplay time and no extra RNG.
- Raw evidence retains encounter/spawn/orb/choice traces, all selection timestamps, final RNG states, level, XP remainder and separate emitted/collected/off-screen/active/cancelled totals per seed. Active XP at the measurement cutoff remains active; teardown is not misreported as off-screen loss. No run is cancelled before the cutoff.

## Baseline distributions

Times are gameplay seconds. Quantiles use nearest rank over all 100 seeds in each group. The target is **20-25 s for the first choice**, then **35-50 s for each of the next four intervals**. Missing observations would remain right-censored; uncertain quantiles are labeled censored rather than silently excluding slow seeds. There are **zero censored first-five observations** in this baseline.

| Mode / collection | Observation | p10 | Median | p90 |
| --- | --- | ---: | ---: | ---: |
| Solo / perfect | First choice | 19.00 | 23.00 | 30.00 |
| Solo / perfect | Choice 1 → 2 | 15.72 | 21.73 | 30.00 |
| Solo / perfect | Choice 2 → 3 | 20.60 | 26.47 | 33.03 |
| Solo / perfect | Choice 3 → 4 | 25.33 | 33.07 | 41.48 |
| Solo / perfect | Choice 4 → 5 | 27.05 | 35.50 | 43.02 |
| Solo / every fifth missed | First choice | 20.25 | 26.38 | 33.00 |
| Solo / every fifth missed | Choice 1 → 2 | 20.07 | 27.92 | 37.68 |
| Solo / every fifth missed | Choice 2 → 3 | 24.60 | 33.22 | 40.62 |
| Solo / every fifth missed | Choice 3 → 4 | 30.75 | 38.38 | 46.52 |
| Solo / every fifth missed | Choice 4 → 5 | 26.08 | 38.17 | 48.22 |
| Co-op / perfect | First choice | 16.85 | 20.87 | 26.37 |
| Co-op / perfect | Choice 1 → 2 | 11.78 | 19.03 | 24.92 |
| Co-op / perfect | Choice 2 → 3 | 18.55 | 23.82 | 28.83 |
| Co-op / perfect | Choice 3 → 4 | 21.17 | 27.87 | 35.72 |
| Co-op / perfect | Choice 4 → 5 | 26.95 | 32.53 | 41.08 |
| Co-op / every fifth missed | First choice | 17.92 | 23.07 | 30.05 |
| Co-op / every fifth missed | Choice 1 → 2 | 17.85 | 24.38 | 31.33 |
| Co-op / every fifth missed | Choice 2 → 3 | 21.27 | 27.50 | 34.70 |
| Co-op / every fifth missed | Choice 3 → 4 | 26.98 | 33.97 | 42.15 |
| Co-op / every fifth missed | Choice 4 → 5 | 25.80 | 35.73 | 45.65 |

Totals below sum the 100 unique traces per group, excluding the verification repetition. Every individual run satisfies `emitted = collected + offscreen_lost + active + cancelled`.

| Mode / collection | Emitted | Collected | Off-screen | Active | Cancelled | Final levels | Peak entries |
| --- | ---: | ---: | ---: | ---: | ---: | --- | ---: |
| Solo / perfect | 32,934 | 32,516 | 0 | 418 | 0 | 9-11 | 9 |
| Solo / every fifth missed | 32,934 | 25,971 | 6,312 | 651 | 0 | 8-10 | 10 |
| Co-op / perfect | 39,351 | 38,913 | 0 | 438 | 0 | 10-11 | 10 |
| Co-op / every fifth missed | 39,351 | 31,420 | 7,183 | 748 | 0 | 9-10 | 11 |

The 20% missed-event schedule selects 6,653 solo XP and 7,551 co-op XP across all seeds; these are not exactly 20% of emitted value. Some missed XP is still active at cutoff. Encounter/killing traces and emitted totals are identical between collection profiles in each mode, as required by the scripted fixture.

## Bounded reward-only calibration search

`tests/fixtures/xp_economy_candidates.gd` replays the recorded materializations with the shipped `Enemy._xp_for_roll` implementation and reconstructed drop stream. Before comparing candidates it verifies every baseline kill count, final drop RNG state, emitted total and selection tick. Final replay: **zero failures**. Integer ticks are compared after JSON deserialization to avoid decimal serialization precision affecting equality.

Only duplicated XP reward definitions change in this screening projection. It does not retain a gameplay adjustment and does not replace a full repeated fixture run for a retained candidate. Parameters: common drone/fighter XP chance **20/25/30/35/40/45%**, ordinary asteroid chance **20/35/50%**, large-asteroid value **1/2/3**. This yields **54 distinct combinations**; the output has 55 records because it also contains the explicit baseline verification. Other XP rewards, plasma rolls/amounts, director pressure, health, weapons, threshold formula and slots remain fixed.

Examples, solo with every fifth event missed:

| Candidate | First | Interval 1 | Interval 2 | Interval 3 | Interval 4 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Baseline: common 45%, asteroid 35%, large value 2 | 26.38 | 27.92 | 33.22 | 38.38 | 38.17 |
| Common 20%, asteroid 35%, large value 2 | 33.25 | 40.33 | 44.92 | 41.37 | 33.78 |
| Best summed distance in this search: common 20%, asteroid 50%, large value 2 | 28.37 | 34.25 | 39.72 | 41.88 | 34.53 |

**None of these tested combinations meets all five solo missed-profile median targets.** Slowing the early choices tends to delay the first beyond 25 seconds. This is a measured tradeoff within the declared search, not a proof that every allowed parameter combination is impossible. No reward or collection revision is retained; the shipped prototype parameters remain the baseline in the contract. Attraction/fall changes cannot fix this fixture's deliberately fixed two-second collection policy, although they can affect real play and must be assessed there.

The maintainer answered **"Tester le rythme actuel d'abord"** after reviewing the measured tradeoff. Retain the current prototype for the three real solo runs before deciding whether to keep the frequent early choices or reopen the numerical economy contract. This authorizes the playtests, not a silent numerical target revision. The target mismatch remains visible; this step is not accepted or complete.

## Three prepared real solo runs

`tests/play_phase_3_economy.gd` prepares normal solo combat with keyboard input and a fixed seed, reconnects progression to that seed's upgrade stream before the deferred director starts, and writes a JSON log to `user://phase_3_solo_<seed>_<timestamp>.json`. It starts in the normal pause menu at time zero: select **RESUME** when ready. It records selection times, requested/applied choices, progression and pool accounting. It stops the observation at five applied choices, death or 300 simulation seconds; a surviving sample opens the normal pause menu. Early closure/restart/title return is labeled separately. Temporary keyboard/window preferences are restored at observation end. Selection/pause time does not advance combat clocks. Feedback fields stay empty until supplied by the maintainer.

Prepared seeds are **69, 29, 4**: their perfect-collection first choices correspond to the measured solo p10/median/p90 (19/23/30 s), respectively. These are fixture percentiles, not predicted human results.

```powershell
$godotExe = 'C:/godot/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = Join-Path (Get-Location) '.godot/phase_2_runtime_validation/qa_phase3_human'
& $godotExe --rendering-method gl_compatibility --path .godot/phase_2_runtime_validation --script res://tests/play_phase_3_economy.gd -- --seed=69
# Repeat separately with --seed=29 and --seed=4.
```

Capture for each run: actual first choice/early intervals, difficulty recovering XP, useful upgrade choices, menu readability and any death. **All three human runs and maintainer feedback are pending.** The existing informal playable feedback about XP visibility is not substituted for these seeded observations. The `--smoke` option verifies seed wiring, restored preferences and the time-zero pause and labels its output `technical-smoke`; it is not human evidence. Seed 69 native smoke passes with clean teardown. The initial headless smoke showed shutdown retention, so native evidence is used for teardown verification.

Technical co-op remains covered by the actual activation/offers suites, including shared XP, independent choices and participant death. Human co-op balance acceptance is still deferred to roadmap Phase 6. No later offensive family has been started.

## Evidence and reproduction

- [Complete baseline traces, gzip JSON](step_5_economy_baseline.json.gz): 400 unique traces plus the fixture's runtime/repeat metadata and distributions. Uncompressed SHA-256: `F25C5948CA6B01217096155B35991A5CEEEE600FFF585163879FB462DB7FA689`.
- [Candidate screening results](step_5_economy_candidates.json): declared parameter combinations and all four groups' median vectors; baseline replay failures = 0.
- Rebased foundation regressions: progression **102**, offers **1,957**, XP rewards **2,526**, XP pool/audio **30**, native activation **76** checks, all passing. These selected suites do not imply every repository test passes.

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/phase_2_runtime_validation/qa_phase3_economy'
& $godotExe --headless --path .godot/phase_2_runtime_validation --script res://tests/test_xp_economy.gd
& $godotExe --headless --path .godot/phase_2_runtime_validation --script res://tests/fixtures/xp_economy_candidates.gd
```

The full fixture writes `user://xp_economy.json`; the candidate script reads it and writes `user://xp_economy_candidates.json`. Both commands must use the same isolated APPDATA. `-- --seeds=1` is a fast smoke subset, not the 100-seed acceptance run. For another checkout, prepare/import an addon-free project copy as described in `docs/phase_3_validation.md`, or use the normal project path with its installed local tooling. A retained numerical revision requires the full 100-seed repeated fixture again, an explicit contract update and the three human observations.
