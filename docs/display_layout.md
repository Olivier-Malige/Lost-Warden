# Display Layout

## Target canvas

The logical canvas is 1066 by 800 pixels, a near-4:3 format selected to map almost one-to-one to the Steam Deck's 1280 by 800 display while keeping the compact framing and low-resolution character of the original game.

The active combat rectangle is the centered 866 by 800 area. Player bounds include a small safety margin inside it, from `(118, 24)` to `(948, 784)`. Enemy spawn lanes are distributed from `x = 125` to `x = 941` and start above the visible area.

Gameplay does not use a camera zoom. The larger logical canvas reveals more space for large encounters while the HUD remains pixel-stable on its own canvas layer.

| Region | Logical rectangle | Purpose |
|---|---:|---|
| Left rail | `0, 0, 100, 800` | Player one energy, score, and run information |
| Playfield | `100, 0, 866, 800` | Player movement, enemies, projectiles, and encounters |
| Right rail | `966, 0, 100, 800` | Player two energy, wave, danger, and boss status |

The rails are non-playable interface space. They must not look like obstacles and must not contain decorative computer frames or legacy franchise silhouettes.

## Scaling rules

- Use `viewport` stretching with aspect `keep`.
- Preserve the near-4:3 canvas at every physical resolution.
- Never extend player or enemy movement into the HUD rails.
- On the Steam Deck's 1280 by 800 display, center the canvas with pillarboxing instead of distorting sprites.
- The Web export uses Godot's adaptive canvas resize policy.
- Browser fullscreen is only entered from the explicit menu action.

## Screen placement

Title, high-score, pause, game-over, and gameplay scenes use the same 1066 by 800 logical canvas. No camera zoom is used.

Backgrounds may render behind the rails, but gameplay sprites must remain inside the central square. HUD text must retain clear contrast against the background.

## Background motion

All retained parallax backgrounds use a base scroll speed of 60 logical pixels per second. The nearest layer uses a 1.1 motion scale for a subtle 66-pixel-per-second foreground drift, while the middle and far layers retain their original 48 and 30-pixel-per-second speeds. Star sprites render at 75% scale, with matching parallax tiling, and the background script applies velocity once per frame to avoid accumulated acceleration.

Background motion is visual feedback only. It stays independent from gameplay RNG, player speed, enemy movement, and encounter timing.

Do not raise this value as part of the Phase 1 pace increase without a separate visual-readability review.
