# Release Notes alpha-9.1

Version: 0.9.1
Date: 2026-10-15
Engine: Godot 4.7.2 stable

## New Features

- None. This is a bug-fix update to alpha 9.

## Improvements

- Blend the horizontal edges of nebula clouds without stretching the artwork or changing stars, planets, and debris.
- Adapt background repetition to the viewport width, including window resizing and ultrawide displays.

## Bug Fixes

- Continue counting waves beyond 18 while retaining the existing endless encounter loop and difficulty scaling.
- Include the just-finished run in the highest-wave and high-score records before displaying the game-over screen.
- Preserve Red Rift nebula transparency instead of mistaking faint red clouds for opaque stars.
- Preserve the transparency of faint debris edges.
- Prevent background elements on the right from appearing and disappearing during camera movement on wide displays.

## Breaking Changes

- None. Existing saves remain compatible. Power-up balance and encounter compositions are unchanged.

## Validation

- Wave progression: 754 checks covering solo/co-op, endless loops, saved records, debug navigation, and a new run.
- Compatibility-renderer background regression: 139 checks covering transparency, horizontal seams, viewport widths, resizing, and camera offsets.
- Background, native-scale, title-screen, and screen-transition regressions pass.
- Existing collision-alignment and enemy-animation-frame failures are independent of this patch and were reproduced before its changes.

## Builds

- Windows x86_64: extract the archive and run `lost-warden.exe` beside `lost-warden.pck`.
- Linux x86_64: extract the archive, make `lost-warden.x86_64` executable if needed, then run it beside `lost-warden.pck`.
- Web: serve the extracted directory over HTTP(S), opening `index.html`.
