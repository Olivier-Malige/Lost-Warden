# Step 7 — piercing and critical hits

Implemented and verified locally on 2026-10-20 with Godot 4.7.2 official, Windows and the addon-free runtime. Native captures use OpenGL compatibility on the RTX 3060. The maintainer requested the next numbered step after reviewing step 6. Step 5's two remaining solo observations and qualitative feedback remain deferred; this delivery does not accept or retune the XP economy.

## Delivered behavior

- `piercing` and `critical_hits` are now the only two additional live families. Each has weight 10, three authored ranks and one personal offensive slot regardless of rank. The catalog contains twelve entries. Existing offers, rank caps, seven-slot HUD and personal confirmation rules apply.
- Piercing accepts the initial target plus 1/2/3 extra targets. Each accepted distinct logical group reduces subsequent direct damage by x0.8. Re-entry and overlapping boss surfaces neither repeat damage nor consume an extra traversal. Armor stops the shot even when it rejects damage. Existing primary/side collision shapes and animation tracks remain unchanged.
- Critical chance is the loadout's authored 10/20/30 percent. A compatible emitted projectile consumes exactly one draw from its owner's combat RNG and preserves the result for every piercing contact. Unranked projectiles consume no critical draw. Direct damage doubles; deferred secondary amounts remain based on pre-critical damage. The base DAMAGE multiplier is applied once, before these modifiers.
- Primary and side cannons use their explicitly assigned piercing textures. Pool reuse restores the original texture, decay, target budget and snapshot. Signature plasma and reflected shots receive no new modifier. Pause freezes projectiles and critical animation; owner DYING and generation cancellation retain the step-6 rules.
- Critical feedback is an owner-colored, six-frame, 240 ms sprite sequence. It creates no collision object, accepts at most 32 simultaneous effects across the tree, pauses normally and is removed with its world. No new sound is introduced.

## Verification

Commands use separate ignored APPDATA directories and the existing `.godot/phase_2_runtime_validation` project:

```powershell
$godotExe = 'C:/godot/Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path .godot/phase_2_runtime_validation --script res://tests/player/test_piercing_and_critical_hits.gd
& $godotExe --rendering-method gl_compatibility --path .godot/phase_2_runtime_validation --script res://tests/player/test_piercing_and_critical_hits.gd
& $godotExe --headless --path .godot/phase_2_runtime_validation --script res://tests/test_upgrade_offers.gd
```

| Suite | Actual result |
| --- | --- |
| Piercing and critical hits | **708 native checks PASS**. Actual Area2D contacts for all piercing ranks, all critical rank thresholds/emissions, combined damage, re-entry, simultaneous distinct targets, armor, overlapping boss parts, lethal critical XP ownership, P1→P2 reuse, primary/side shots, plasma, real shield reflection, pause, feedback cap/expiry, five world-removal cycles, DYING and stale generations. Earlier headless revision: 706 checks PASS, before the last two lethal-critical assertions. |
| Critical replay evidence | [480 emission records](step_7_critical_traces.json): seeds 0/1/42/99, P1/P2, with and without unrelated encounter/enemy/drop/offer/cosmetic draws. Exact traces repeat; emissions do not alter unrelated streams or the partner's stream. Forced zero/below/equal/above/one boundary rolls use the production threshold function; no statistical pass/fail tolerance. SHA-256: `650ECC7FA33EFEA431E9D81AB33354B5A353532FE7E9B3C0ED0AC02255587D63`. |
| Upgrade offers | **1,993 checks PASS**. The first offer reserves any completed offensive, rather than requiring side shots specifically. Synthetic future-capacity fixtures start after the two newly delivered effect enums. |
| Progression activation | **76 native checks PASS**. The exhausted-build fixture now caps both new families before asserting its final side-shot rank and automatic salvage. Beam overdrive remains outside the three acquired offensive families. |
| Upgrade selection | **42 headless checks PASS**. |
| Accepted-hit infrastructure | **41 checks PASS**. |
| Boss destructible parts | **73 checks PASS**. |
| Beam upgrades / beam impact | **36 / 18 checks PASS**. |
| Shield throwback / fire input | **PASS**; fire input executed separately to avoid the previously recorded wall-clock sensitivity. |
| Foundation collision alignment | **PASS**, `-- --foundation-only`. |

The final native suite exits cleanly. One earlier native revision passed its assertions but reported two retained objects/one resource during shutdown; a verbose headless run and verbose native rerun both exited cleanly without a production change. Do not infer that every repository suite is green: historical full enemy-feedback/collision fixtures remain outside this checkpoint. Full 800-run economy measurement and full build/performance acceptance are not rerun or claimed here. Step 5's archived results describe the former ten-entry catalog; the XP curve, rewards and encounter pressure remain unchanged.

## Art and visual evidence

All artwork was produced through the Aseprite MCP. Sources, exported PNGs and JSON frame/tag mappings are recorded in [the inventory](../art_audio_inventory.md#step-7--piercing-and-critical-art--2026-10-20).

An Aseprite API audit composites every source frame and compares every exported pixel. All five source/export pairs match exactly, use binary alpha and only Lost Warden 64 colors. Both piercing atlases retain every original alpha byte and therefore their visible footprints; collision geometry is unchanged. Opaque-pixel counts: primary 548, side 188, critical 254, full menu atlas 26,006, miniature atlas 1,678.

Inspected local captures in `.godot/phase_2_runtime_validation/`:

- `step7_solo_choices.webp` and `step7_coop_choices.webp`: native 64px effect cards, distinct piercing plates/critical star, personal miniature rows and readable numeric rank effects.
- `step7_{solo,coop}_impact_{0,1,3,5}.webp`: 711x400 expanded native game viewport, original HUD and actual projectile textures; four sampled frames of the new critical sequence. These controlled presentation captures deliberately position the visual samples; real collision/damage behavior is separately asserted above.

Pixel review: `ICON-PIXEL-LOCK`, `ICON-META`, `COLOR-FX`, `LIGHT-PLAY-SEP`, `LIGHT-PART-OCCLUDE` and `COMP-SAFE-EDGE` each score **2/2** for these new assets/captures. This is a focused visual review, not a full UI certification or maintainer style acceptance. Neither `animation_rework` atlases nor signature-plasma mappings are changed.

Stop at step 7 for review. Step 8 (homing micro-missiles) remains pending. Dedicated selection audio and the outstanding human economy/co-op acceptance remain separate.

## Maintainer-approved readability follow-up

After reviewing this delivery, the maintainer approved stronger critical feedback and replacing gameplay score/combo displays with an elimination counter. The preceding 16px/240ms art audit records the initial checkpoint; the current source/export is **24px/300ms**, 144x48 sheet, owner rows 0/24, cell pivot (12,12), six 50ms frames. Fresh Aseprite audit: exact source/export equality, binary alpha, Lost Warden 64, 482 opaque pixels. Ordinary critical targets hold their existing hit shader at full intensity for 80ms then fade over 120ms; surviving boss cannons use 80ms hold plus 160ms fade. No damage, proc chance, collision geometry or audio changes accompany this presentation revision.

`global.eliminations` owns a run-only shared count, updated through `Events.eliminations_changed`. Player-owned enemy kills count once, including a boss hull. Asteroid families, optional boss parts, uncredited deaths and score-only salvage do not increase it. HUD points/combo labels and world floating-score presentation are removed; exhausted-build salvage feedback now reads `SALVAGE RECOVERED` without a point amount. Existing internal scoring and save/record behavior remain intact, with no save-schema change. Level, its progress bar, survival clock and personal builds remain visible.

`tests/test_elimination_hud.gd`: **25 native checks PASS**, including actual kill/reject paths, shared P1/P2 count, hazard/part exclusion, boss count, score-only reward, suppressed legacy popup events, zero-on-restart, longer accepted critical flashes and teardown. Existing focused regressions pass: **708 combat**, **76 native progression**, **73 boss-part**, **41 accepted-hit** checks. This follow-up does not claim the historical full enemy-feedback suite or the pending economy/balance acceptance passed.

After removing the salvage point amount, progression activation also passes **67 headless checks**; that headless shutdown reports three retained objects/one resource, consistent with the previously documented headless-only retention category. The native follow-up fixture and native progression checks exit cleanly. No test or production timing was weakened to hide this warning.

Inspected actual 640x400 captures `critical_hud_{0,1,3,5}.webp` in the ignored runtime: legible ELIMINATIONS above the left build rail; survival/level on the right; no points/combo overlays; clear red/blue critical stars and their fragment decay. `LIGHT-HIT-SPARK`, `LIGHT-PART-OCCLUDE`, `ICON-PIXEL-LOCK` and `COMP-SAFE-EDGE` score **2/2** for this focused review. The sample stars are positioned deliberately; accepted-hit target flashing and kill counting are separately asserted through the real enemy/boss paths.
