# Armored Depth Sprite Pass — 2026-09-08

## Baseline

The maintainer requested a commit of the current work followed by a pass bringing existing sprites closer to the accepted industrial reference. Baseline commits: `516d94a` (art and test libraries), `6c2775f` (existing pickup/impact feedback). The generation recipe remains recorded in `9f44965`.

## Native Source Changes

Added an editable `Armored Depth` layer to 15 existing sources, with family-specific recessed plates, vents, structural ribs and localized edge highlights:

- Razor Fighter and elite, Talon Interceptor and elite, Razor Wing Drone and elite, Siege Turret and elite, Grave Carrier and elite.
- Furnace Bomber, Lance Sniper and Dive Hunter test prototypes.
- Nomad banking master, exported for both teams.
- Dread Ark boss phase master.

The pass adapts the accepted dark industrial material language to the existing logical resolution. It does not reproduce all high-resolution concept details or change silhouettes to match the concept ships. Existing sources, dimensions, pivots and animation layouts remain the production basis. Colored markings and lights are protected; hull detail is applied to neutral surfaces only. Hit and destruction frames are unchanged. FX, pickups, asteroid surfaces and backgrounds were not restyled in this hull pass.

Sources remain at their existing paths under `assets/sources/`. Corresponding horizontal PNG sheets and the affected player/prototype GIFs are synchronized. The prototype enemy gallery was refreshed. No runtime scene or script changed during this pass, and no new integration is implied for previously unconnected assets.

## Review

`assets/art/sprite_references/armored_depth_comparison.png` shows before on the left and after on the right within each pair. Top row: fighter, carrier, Nomad, bomber. Bottom: boss. The editable comparison lives at `assets/sources/art/armored_depth_comparison.aseprite`. Hide `Armored Depth` in any modified source to compare against its prior native layers.

## Verification

All 15 sources were compared against copies captured immediately after the baseline commits. Checks passed for dimensions, frame count, durations, tag names and ranges, silhouette alpha, protected functional colors, unchanged hit/destruction renders, and pixel agreement between each source and its PNG export. Each source has a nonzero pixel change. The blue Nomad export additionally passed dimensions, silhouette and team-color preservation checks. Static before/after review and `git diff --check` passed. Full gameplay visual review remains outstanding.

This pass is left uncommitted for review, separate from the requested baseline commits.
