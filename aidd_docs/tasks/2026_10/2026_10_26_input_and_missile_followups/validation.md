# Upgrade confirmation and upper-target missile follow-ups — 2026-10-26

The maintainer requested separate upgrade confirmation controls to prevent accidental choices from firing, then requested that a missed homing missile switch to the nearest target above it. Both changes are implemented locally, without commits or unrelated balance changes.

## Upgrade confirmation

- Dedicated InputMap actions separate confirmation from firing for solo, keyboard and both gamepads. Enter/keypad Enter confirms on keyboard; Start confirms on the owner's assigned gamepad. Mouse confirmation remains available.
- Main routes confirmation to the selection before the shared pause action. An unassigned controller cannot confirm another player's card or turn Start into a nested pause menu. Start retains normal pause behavior outside selection. Other existing pause-menu bindings remain available.
- Holding fire neither confirms nor blocks navigation/confirmation. Confirmation held at opening, controller reassignment or the next queued choice must be released. Opening delays, keyboard echo filtering, per-player readiness, stale-ID protection and inspector/menu suspension remain.
- Co-op hints show `D-PAD / START` or `ARROWS / ENTER`. Solo shows both on two lines. Inspected the native co-op and solo captures: hints fit their existing bounds, and confirmation buttons remain legible.

## Missile retargeting

- Initial acquisition retains the authored 90-degree launch cone. A missing, passed or invalid lock selects the nearest eligible, unobstructed enemy strictly above the missile, within the existing 220px range. Replacement candidates may lie outside the launch cone.
- Replacement guidance retains any target in the upper half-plane. Subsequent losses may acquire another target; missed logical groups are excluded to avoid circling back to the same enemy or another part of the same boss. A lost existing lock searches immediately; when no replacement is available, searches retry at most every 100ms.
- Speed 240px/s, turn limit 240 degrees/s, 1.8s total lifetime, rank damage/cadence, three active/reserved missiles per owner, critical attribution and physical-only hit delivery are preserved. Retargeting creates no new hit snapshot or lifetime. Pool reuse clears missed groups and retry state.
- The upgrade description explains the new behavior. Other weapons continue using their existing targeting rules; shared CombatTargeting was unchanged.

## Verification

Godot 4.7.2, addon-free validation project, isolated APPDATA directories. Native runs use OpenGL Compatibility on the RTX 3060.

| Suite | Headless assertions | Native assertions | Result |
| --- | ---: | ---: | --- |
| Upgrade selection | 76 | 82 | Pass |
| Micro-missiles | 438 | 462 | Pass |

Selection regressions cover repeated fire presses, holding fire while navigating/confirming, held confirmation at opening and across queued levels, echo rejection, controller reassignment and isolation, Enter/Start routing through Main, solo confirmation, ordinary Start pause and nested menu/inspector behavior. Native selection stderr is empty.

Missile regressions cover a living target passed by the missile, closer lower/same-height enemies being rejected, nearest upper targets outside the launch cone, exclusion of previously missed targets, multiple consecutive target losses, a late replacement after an empty search, bounded turning/lifetime, destroyed-target physical interception, roots/reservations, critical RNG and pool/world cleanup. Existing solo/co-op native flight, impacts, rank progression and choice captures also pass.

The headless selection run and native missile run report two retained objects and one resource at shutdown, matching the previously documented selection/music warning. Their behavior assertions pass; no audio code was changed. The native selection run is clean. Logs `safe_upgrade_confirm_native*.log` and `missile_upper_retarget_native*.log` are in the ignored validation project.

The focused early test failures exposed a Start press from an unassigned controller entering pause, and delayed reacquisition of a freed WeakRef target. Both were corrected and the final suites above rerun. Test fixtures were updated for the approved broader upper-target replacement rule; no damage is applied merely by changing targets. `git diff --check` passes.
