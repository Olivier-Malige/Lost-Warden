# Gameplay animation library — 2026-09-09

## Scope and delivery

Following the accepted Dread Ark animation pass, the maintainer requested the other animated sprites, including effects. This pass produces **54 editable Aseprite masters**, **55 PNG atlases** (including both Nomad teams), matching JSON exports, a machine-readable catalog, an interactive comparison gallery and two GIF reels.

Sources are under `assets/sources/{enemies,player,combat,effects}/animation_rework/`. Matching exports are under `assets/sprites/{enemies,player,combat,effects}/animation_rework/`. The complete path, dimensions, frame count, animation ranges, original-source mapping and proposed event markers for every asset live in `assets/sprites/animation_rework_catalog.json`.

The new state counts require explicit runtime mapping. These are dedicated animation libraries: existing production sources, runtime sheets, scenes, scripts, collision shapes and the accepted Dread Ark hull remain unchanged. Existing uncommitted art was used as the baseline, including the armored-depth work. The baseline frames of extended libraries remain pixel-identical in visible color and alpha; conversion from indexed to RGB may clear RGB bytes under fully transparent pixels.

Static icons, static reactor particles, backgrounds, reference boards and obsolete legacy alternatives are outside the animated production set. The Dread Ark hull remains the accepted 87-frame master from the previous pass. Its beam, projectiles and destruction effect are included as separate comparison variants here.

## Review

Open `assets/art/sprite_references/animation_rework/gallery.html` in a browser. The gallery is self-contained: it embeds its comparison sheets and timing data, supports family/search filters, tag selection, pause and 0.5×/1×/2× playback. Source links resolve relative to the repository. A local preview server is optional; opening the HTML file directly also works.

- `enemy_actions.gif`: top row Razor Fighter, Talon Interceptor, Razor Wing Drone, Siege Turret; bottom row Grave Carrier, Dive Hunter, Furnace Bomber, Lance Sniper.
- `effect_actions.gif`: top row metal impact, gold collection, shield hit, heavy charge; bottom row muzzle flash, electrical damage, boosted thruster, shield break.

Both reels live beside the gallery. Their montage sampling is for inspection; individual atlas JSON retains the authored frame timings. Full action reels demonstrate transitions and are not intended to loop as a combat controller.

## Enemy families — 13 masters

| Family | New visual information | Proposed timing / use |
|---|---|---|
| Razor Fighter + elite | Two visible lower barrels, three-step charge, flash and recoil | 450 ms charge, 150 ms fire, 400 ms recovery |
| Talon Interceptor + elite | Three distinct discharge positions for its spread | Same timing; keep the three projectile origins explicit |
| Razor Wing Drone + elite | Wings open to brake, then close into the boost pose | 500 ms preparation, 180 ms commit, 400 ms recovery; movement feedback, no invented gun attack |
| Siege Turret + elite | A downward aperture and barrel for aimed fire; distributed perimeter points for radial fire | 600 ms aimed warning; 700 ms radial warning; only the radial state lights the perimeter |
| Grave Carrier + elite | Separate port, starboard and lower hull guns | Port/starboard: 600 ms charge, 180 ms fire, 520 ms recovery; hull: 600/210/650 ms |
| Dive Hunter | Wing spread during windup, folded dive pose, softer recovery | 600 ms windup, 240 ms commit, 550 ms recovery |
| Furnace Bomber | Sliding payload shutters, exposed payload, empty bay after release | 660 ms opening, 270 ms release, 600 ms closing |
| Lance Sniper | Charge progresses down the cannon, short discharge, cooling vents | 800 ms lock/charge, 150 ms fire, 780 ms cooling |

Prepared states ending in `ready` are deliberately steady. Charge, firing and recovery tags play once, driven by gameplay. Fire markers in the catalog are zero-based and refer to the first firing frame, except the bomber: its marker is the third release frame, after the baked-in payload has left the bay. Do not spawn an extra projectile over a still-visible baked payload.

The new gun origins are documented in the catalog. These are nominal muzzle positions before recoil and are not a claim that existing runtime markers or collider orientations already match. Wing movement changes the art footprint; integration must check it against the current collision shapes. Elite plates remain visible without restoring the old aura layers.

## Player and weapons — 5 masters

- **Nomad:** preserves all 13 banking poses and shared team geometry. Banking enters quickly and returns more softly; mirrored directions use identical timings. Appends primary fire/recovery, beam charge/release, boost and damage-warning states. `boost` and charge cues are available artwork, not newly implemented abilities. Red export shows `Player Red` + `Action Red`; blue export shows `Player Blue` + `Action Blue`, with the opposite pair hidden.
- **Primary and side pulse shots:** preserve the five original power-level cells, then append four-frame flow loops per level. Each cell still contains its existing red/blue team rows. Do not play through power levels as an animation.
- **Plasma beam:** retains five four-frame power loops and both team rows. Detail scrolls within each team's tile while the beam footprint remains continuous; 65 ms frames.
- **Nomad shield:** preserves the original 24 cells and adds a four-frame reflection for each of six charge levels and both teams. The impact compresses into a bright center, splits into return sparks, then settles. Use the matching `playerN_reflect_level_M` tag without changing the selected charge level. The original multi-cell idle ranges are charge alternatives, not an idle animation to cycle through.

Nomad primary fire/recovery lasts 120/280 ms; beam preparation/release lasts 540/150 ms. Gameplay owns weapon cadence. The art library does not introduce mandatory charge delays or alter existing player responsiveness.

## Combat projectiles — 6 masters

Fighter, interceptor, side dart, siege charge and the three Dread Ark projectile families retain their existing shapes. Traveling bright accents and shorter interceptor timing distinguish their flow. Siege impact timing is separate from its flight pulse. The Dread Ark beam scrolls its field over a continuous core; its four frames last 75 ms each. These are visual variants, not changes to projectile speed, damage or collision.

## Effects — 28 masters

The 26 test-library effects are revised by role rather than sharing a single pulse:

- Metal/armor/asteroid/energy impacts: short initial contact, expanding fragments, then a transparent ending. Armor and asteroid bursts retain darker fragments.
- Four collection colors: particles converge on the anchor before a small confirmation accent disperses. These are collection effects, not persistent pickup sprites.
- Shield activation: growing arc settles into a complete shield. **Hold the final pose** until the owner switches state. Shield hits briefly dent the struck side; break effects separate into cooling arcs and end transparent.
- Single/double/plasma muzzle flashes: an immediate short core, brief peak and fast disappearance; all face up around `(12,24)`.
- Small/heavy/overload charges: arcs contract into the center with an increasingly clear core. **Hold the final charged pose** before a shot or explicit cancellation. The inherited `burst` tag name does not mean the final frame is transparent.
- Electrical damage: intermittent connections and deliberate dark gaps. Embers and reactor leaks flow away from their anchor instead of blinking as a single shape.
- Thrusters: steady short idle, longer coherent boost, irregular damaged output. Anchor `(12,6)` is retained; plume extends down.
- Three debris families: authored rotational poses are preserved with sparse moving edge highlights, rather than whole-object flashes.

The Nomad and Dread Ark explosion variants preserve their existing burst silhouettes, shorten the initial impulse, and give cooling fragments more time. Sparse debris accents replace uniform timing emphasis. Enemy-library baseline explosions remain available unchanged.

## Asteroids — 2 masters

Small and large Dark Slate variants retain their existing rotation alternatives and damage cells. Breakup timing now separates the fast initial event from slower rubble, with sparse cooling accents. Do not cycle all alternatives as one rotation animation. Use the atlas rectangles: these exports are eight-column libraries and are not drop-in replacements for the original atlas layouts.

## Export and verification contract

- Eight-column row atlases, no trimming or padding; use per-frame JSON rectangles rather than assuming the former layouts.
- Aseprite frame numbers are one-based; JSON and catalog frame/event indices are zero-based.
- Every source has its own editable layers. Existing source paths and comparisons are recorded in the catalog.
- **930 frames** independently exported and compared pixel-for-pixel against all 54 atlas layouts.
- Binary alpha and the Lost Warden 24 palette verified across all 55 PNGs.
- Tag bounds, extended-library baseline visibility, non-static new enemy action tags, transparent transient endings and held charge/activation endings verified.
- Red and blue Nomad exports have identical alpha footprints and different team colors.
- Representative enemy charge/discharge and effect frames were visually inspected. Gallery filtering, tag selection, speed selection and pause were exercised in the browser; no console errors were reported.

This is asset-level verification. In-game projectile/animation synchronization, collision alignment, visual readability amid combat, sustained-beam seams and solo/co-op behavior remain integration work. No gameplay roadmap phase was implemented and no commit was created.
