---
status: implemented
---

# Plan: close-range defensive survival builds

Source: maintainer-approved implementation plan on 2026-10-22. Deliver shield, reactive armor and retaliation pulse, then stop before ricochet. Do not commit or publish without a separate request.

## Approved behavior

- Three utility families, each three ranks, sharing the existing three utility slots.
- Shield: radius 20, 3/5/7 charges, 8/6/4-second automatic full recharge only after depletion. A projectile consumes one charge and reverses its original velocity/damage. Bodies consume at most one charge per logical group per 0.5 seconds; continuous beams retain their 0.35-second cadence. Last charge absorbs its entire impact. Rank changes preserve spent charges or recharge progress.
- Reactive armor: ordinary post-injury protection becomes 1.25/1.50/1.75 seconds. Slowdown and hit-color duration remain one second. Continuous beams still bypass ordinary protection.
- Retaliation: shield rupture or a nonfatal hull injury creates one pulse, with a four-second owner cooldown. Damage 2/3/4 receives common DAMAGE once, radius 32/40/48, expansion 120ms, active through 160ms, inactive tail through 320ms. Each enemy/boss group is hit once; unreflected hostile shots reached by the wave are erased. Explicit armor blocks it. No criticals or recursive modifiers.
- HUD communicates through Events.defense_state_changed. Original Aseprite MCP art covers sphere, contact, rupture, return, pulse, cards and miniatures. Preserve the existing palette, player colors and other atlas columns.
- Pause, owner death, world teardown, pooling and co-op ownership must remain safe.

## Delivery steps

1. [Data and incoming combat](phase-1.md).
2. [Art and presentation](phase-2.md).
3. [Validation and review](phase-3.md).

## Acceptance

Actual projectile/body/beam collisions, rank transitions, all three family combinations, pulse timing/geometry/occlusion, actual HP changes, owner isolation, pause/death/restart/pooling and VFX saturation must pass. Inspect native solo/co-op sequences and selection states; run affected regressions, GDScript diagnostics and source/export/palette checks. Keep Phase 3 and broad balance acceptance open.

## Outcome

Implemented and verified locally. See [validation evidence](validation.md). Await maintainer playtest before ricochet; no commit or publication requested.
