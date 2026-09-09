# Simple Starfield Variant

A preparation variant of the two textures actually used by `scenes/world/background.tscn`. It preserves the original sparse starfield aesthetic, pixel shapes, star colors, alpha and 1600×1200 dimensions. Only star positions change; no nebula, planet or wreckage was added.

- `background.png`: 108 stars, matching the current first texture.
- `background_2.png`: 58 stars, matching the texture reused by the current second and third parallax planes.
- Native source: `assets/sources/world/starfield_variant/starfield_variant.aseprite`, one frame with two separately editable layers.
- `preview.png`: static half-size composition over Void, approximating the current layer modulation and vertical offset. It is a preview, not a gameplay screenshot or replacement texture.

Positions use deterministic seed 17092026 on a four-pixel grid, with separation between stars and transparent boundary margins. Validation passed for matching dimensions and visible pixel/color counts against both originals, a changed layout, and transparent outer rows/columns. Existing game textures, scene settings and code remain unchanged. No commit was requested for this variant.
