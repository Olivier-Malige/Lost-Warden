# Debug screen

While `global.Debug` is enabled, a compact overlay appears automatically during gameplay. **F11** toggles it, showing FPS, internal danger, enemy bodies/cap/reservations, threat budget and encounter number/time remaining in the right HUD rail.

**F10** opens the full inspector and pauses gameplay. F10, Start or CLOSE returns to the previous compact visibility and restores the previous pause state. A pre-existing pause menu remains paused. Full view consumes gameplay/menu input; close it before using combat cheats. Screen transitions, disabling debug or freeing the owner release only pauses acquired by the inspector.

Keyboard navigation in full view: Left/Right or Tab/Shift-Tab cycle tabs, wrapping at either end; Up/Down scroll the current page; PageUp/PageDown scroll by a page; Home/End jump to the top/bottom; Escape closes the inspector with the same pause restoration as F10. Held scroll keys repeat, while tab changes require a fresh press. These controls leave compact-mode gameplay input unchanged. Mouse tabs, scrolling and buttons remain available.

## Pages

| Page | Information |
| --- | --- |
| Run | Seed, mode, simulation state, survival/regular time, danger/offset, score/combo, encounter ID/history/time, threat budget/rate, formation timing, occupied/reserved slots, recorded spawns and removals, scaling, elite/boss scheduling model |
| Enemies | Alive/exploding bodies, elites, cap usage, per-family counts and remaining health, current formation rules, lane ranges, threat costs, selection weights and available family capacity |
| Players | Both players' controllers, state, position, health, shield, movement/weapon stats, fire readiness, hit protection, plasma, beam/overdrive state and upgrade ranks |
| Perf | Engine version, FPS, process/physics time, memory, node/resource/orphan counts, draw calls, collision pairs, logical viewport, active/parked projectiles, pool buckets and read-only RNG states |
| Events | Last 64 encounter, player-loss, upgrade, plasma and elite-spawn notifications, newest first |

**COPY** copies the current snapshot as JSON for bug reports. Rich-text pages scroll and retain their scroll position during refresh. The event page is a gameplay journal, not a replacement for Godot's error console.

In compact mode, existing debug controls remain active: F1/F2 lower/raise danger; N skips regular encounters; F3 speed, F4 damage, F5 side shots, F6 shield, F7 fire rate, F8 plasma, F9 maximum stats.

## Data and limits

The panel requests scalar/container snapshots through `Events` at **4 Hz while either view is visible**. World, spawner, player and pool owners produce their own snapshots. The inspector does not read player nodes directly, consume RNG values, spend budgets or mutate combat state. Main screen flow owns the full-view pause. Screen transitions close it; a disabled debug flag hides it and stops requests.

Enemy capacity includes mounted turrets and deferred reservations. Active projectile counts exclude shots marked as pooled. Recorded spawns include immediate mounted turrets; the rolling-minute count uses 60 one-second simulation-time buckets. Spawn/removal counters and the bounded event journal record only while debug is enabled, so enabling it mid-run does not reconstruct earlier activity. Parent-disposed mounted turrets count as other removals; a destroyed enemy leaving the screen is not counted again as an escape.

Elite promotion, boss combat and XP are still pending gameplay work. The panel explicitly distinguishes their existing scheduling/probability model from an implemented runtime feature. Rendering monitors may report zero in headless or unsupported renderer configurations; fixed-FPS preview captures are not performance benchmarks.

## Validation — 2026-10-17

- `tests/test_debug_screen.gd`: **66 checks, 0 failures** in headless and native Compatibility runs, covering F10/F11/guards, pages, both players, compact/live and full/paused behavior, pause-menu restoration, Start/CLOSE, hidden sampling, RNG/budget invariance, bounded logs, upgrades, projectile pooling, kill/escape accounting and teardown. Mouse and keyboard checks inject events through the viewport with the main input handler enabled, covering all tabs, wraparound, Shift-Tab, held-tab suppression, every scrolling shortcut, Escape and compact-mode isolation. The former full-view filter reproduced five failures by consuming clicks before GUI dispatch.
- Encounter spawning **6,004 checks PASS**, progression/records **638 checks PASS**, Alpha 9 combat regression **161 checks PASS**, beam regression PASS and screen transitions PASS. Fire-input regression PASS on an isolated rerun after wall-clock-sensitive assertions failed during concurrent headless runs. The debug test now awaits physics ticks rather than a wall-clock delay when checking live simulation.
- Native Compatibility preview: compact live overlay and all five full-view tabs visually inspected in co-op, with automatic pause/resume and successful return to game over. Local captures: `.godot/phase_2_runtime_validation/debug_compact.webp` and `debug_screen_0.webp` through `debug_screen_4.webp`.
- The previously recorded intermittent MP3 shutdown resource warning remains in some headless suites; the native preview completes without runtime errors.
