# Upgrade confirmation safety — 2026-10-26

The maintainer requested separate confirmation controls to prevent accidental choices while firing.

## Upgrade confirmation

- Dedicated InputMap actions separate confirmation from firing for solo, keyboard and both gamepads. Enter/keypad Enter confirms on keyboard; Start confirms on the owner's assigned gamepad. Mouse confirmation remains available.
- Main routes confirmation to the selection before the shared pause action. An unassigned controller cannot confirm another player's card or turn Start into a nested pause menu. Start retains normal pause behavior outside selection. Other existing pause-menu bindings remain available.
- Holding fire neither confirms nor blocks navigation/confirmation. Confirmation held at opening, controller reassignment or the next queued choice must be released. Opening delays, keyboard echo filtering, per-player readiness, stale-ID protection and inspector/menu suspension remain.
- Co-op hints show `D-PAD / START` or `ARROWS / ENTER`. Solo shows both on two lines. Inspected the native co-op and solo captures: hints fit their existing bounds, and confirmation buttons remain legible.

## Verification

Godot 4.7.2: 76 headless and 82 native selection checks pass. The native selection run has empty stderr. The headless run retains the previously documented selection/music shutdown warning. Native solo/co-op hints and controls are inspected.
