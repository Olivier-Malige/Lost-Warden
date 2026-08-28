# Lost Warden 24 color palette

`Lost Warden 24` is the visual source of truth for future UI and sprite work. It combines a restrained Atari-inspired core with a small bank of bright PICO-8-inspired effects.

The importable Aseprite palette lives at `assets/palettes/lost_warden_24.gpl`.

## Core colors

| ID | Name | Hex | Primary role |
|---:|---|---|---|
| 00 | Void | `#06070C` | Space background and deepest outline |
| 01 | Deep Space | `#101522` | Secondary background and UI panels |
| 02 | Hull Shadow | `#222735` | Ship and environment shadows |
| 03 | Gunmetal | `#464A52` | Dark metal and mid-volume shading |
| 04 | Steel | `#74777D` | Exposed metal and mechanical details |
| 05 | Pale Steel | `#B8B6AE` | Metal highlights and secondary text |
| 06 | Star White | `#F3EBDD` | Stars, highlights and primary text |
| 07 | Oxblood | `#3A0D14` | Red shadows and hostile surfaces |
| 08 | Warden Red | `#9C2020` | Identity color, menus and enemies |
| 09 | Ember | `#E15A43` | Red highlights, damage and heat |
| 10 | Dark Bronze | `#442D18` | Warm shadows, rock and aged metal |
| 11 | Amber | `#9E6B2D` | Warm metal and interface borders |
| 12 | Solar | `#D6D653` | Title, selection and energy |
| 13 | Deep Ion | `#102A4A` | Player-side blue shadows |
| 14 | Ion Blue | `#2D6594` | Allied hulls and cool depth |
| 15 | Ice Blue | `#78B7CF` | Allied highlights and cool UI accents |

## Emissive accents

| ID | Name | Hex | Primary role |
|---:|---|---|---|
| 16 | Neon Red | `#FF5A4D` | Enemy lasers and alerts |
| 17 | Neon Gold | `#FFD35A` | Strong selection, rare rewards and impacts |
| 18 | Plasma Cyan | `#72E0D1` | Allied lasers, reactors and overloads |
| 19 | Shield Violet | `#B979C8` | Shields and special energy |
| 20 | Pickup Green | `#72C95C` | Healing and positive upgrades |
| 21 | Hazard Orange | `#FF9D32` | Mechanical danger and explosions |
| 22 | Laser Pink | `#F05A9D` | Exotic weapons and boss attacks |
| 23 | Flash White | `#FFF8E8` | Explosion cores and maximum highlights |

## Usage rules

- Use colors 00-15 for normal surfaces, shadows, text and interface structure.
- Reserve colors 16-23 for light-emitting effects, interaction feedback and short-lived highlights.
- Keep a regular sprite near six colors: one shadow, two body tones, one highlight and up to two accents.
- Do not use pure black or pure white for regular surfaces. Void and Star White preserve visible detail at both ends of the range.
- Keep emissive colors below roughly ten percent of a normal sprite surface.
- Prefer hard color transitions and authored dithering over gradients on gameplay sprites.
- UI glow should reuse the same hue with reduced opacity; it must not introduce a new color.

## Family mapping

| Family | Recommended colors |
|---|---|
| UI and menus | 00, 01, 06, 08, 11, 12 |
| Player ships | 02-06, 13-15, 18 |
| Regular enemies | 02-05, 07-09, 16 |
| Dread Ark and bosses | 00-05, 07-09, 11, 22 |
| Asteroids and debris | 02-05, 10-11 |
| Shields | 05, 15, 19, 23 |
| Pickups | 12, 17, 20, 23 |
| Explosions | 08-09, 17, 21, 23 |

## Migration order

1. Apply the palette to menus, HUD and screen transitions.
2. Rework the player ship and its weapons to establish the allied ramp.
3. Rework one regular enemy family to validate hostile readability.
4. Rework projectiles, pickups and explosions with the emissive bank.
5. Rework environments and bosses after the gameplay silhouettes are stable.

Do not batch-convert sprites automatically. Each asset should be redrawn or manually indexed so silhouettes, contrast and authored clusters remain intentional.
