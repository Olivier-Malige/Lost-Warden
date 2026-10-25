---
status: implemented
---

# Guard blades: defensive forward double sweep

Source: maintainer-approved implementation plan, 2026-10-24. Add one three-rank offensive family, then stop for playtest before ricochet. No commit or publication requested.

## Contract

- Two simultaneous player-following annular blades, oriented screen-up independently of banking. Inner radius 16, outer radii 60/72/84, angular width 40 degrees. Left center -160 to -90, right -20 to -90 degrees over 160ms, then held together for 120ms while still bright and active, followed by 120ms of inactive fragments. Both arcs meet screen-up instead of crossing past one another, as requested on 2026-10-25; the visible hold supersedes the first endpoint-only revision after maintainer feedback. The maintainer's successive playtest requests supersede the original outer radius of 44 and then fixed radius 60.
- Rank damage 2/3/4 with common DAMAGE once; start-to-start intervals 3/2/1.5 seconds, independent of FIRE_RATE and target presence. One accepted hit per logical enemy/boss per salvo, shared by both blades. No criticals or recursive modifiers.
- Actual hitboxes within the swept sectors receive damage or hostile-shot clearing; armor blocks both. Reflected/ally shots and continuous lasers survive. Projectile clearing uses the pool.
- A small team-colored bar above each ship fills during the final 0.6 seconds before the first salvo and the next salvos, without text or numeric time; subsequent warnings fit inside the normal interval. Rank increases preserve the remaining cooldown fraction (or the initial warning's remaining time) and do not alter an ongoing salvo's stats or reach. Pause freezes all state; death/world teardown cancel damage, audio and root references. Personal co-op timers and three offensive/three utility capacities remain.
- Original Aseprite MCP effects, 64px cards and 16px miniatures use the exact palette/team colors and preserve existing illustrations. Three native rank variants fit in 192px cells to accommodate reach 84 without scaling the central gap. Runtime leading edges and collision angles share the physics clock. Optional empty audio hook.

## Delivery

1. [Combat and data](phase-1.md): resource/enum/catalog, autonomous controller, swept geometry, accepted hits, projectile clearing and lifecycle.
2. [Art and interfaces](phase-2.md): original Aseprite sources/exports, cards/miniatures, selection copy and debug state.
3. [Validation](phase-3.md): measured damage/clearing/timing/geometry, synergies, co-op, lifecycle, native sequences, affected regressions, fresh diagnostics and exact art audits.
4. [Rank progression and warning](phase-4.md): maintainer-requested expanding reach, shorter rank intervals and a brief local countdown; updated rank art/cards and focused validation.

## Acceptance

All approved values and lifecycle rules must be verified with actual HP and physics hitboxes. No ricochet or broad balancing work. Existing local Godot MCP settings stay untouched.

## Outcome

Implemented and verified locally. [Evidence](validation.md) retains the initial 5,323-check full-feature baseline and records the latest revision: 280 dedicated native checks, 3,781 offer checks, 51 selection checks, 106 clean diagnostic documents, exact source/export/import parity and nineteen preserved atlas columns. Stop for guard-build playtest before ricochet. No commit or publication requested.
