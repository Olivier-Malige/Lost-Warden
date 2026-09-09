# Dread Ark attack animation rework

## Scope

The 2026-09-08 art pass preserves the current armored hull and replaces phase-only animation with explicit attack preparation, firing and recovery. This is native Aseprite work; boss combat integration remains in roadmap Phase 2. No runtime behavior or combat balance changes are included.

Source: `assets/sources/bosses/dread_ark_128x96.ase`. The two new editable layers are `Weapon Mechanisms` and `Attack Signals`. The old `Engine Array` and `Phase Accents` layers remain hidden as references. Existing hull layers and slices are retained from the working source.

The lower appendages now have distinct roles: port/starboard barrels with recessed muzzles and mechanical recoil, a central split-shutter beam aperture, and four recessed amber propulsion vents. The vents have no downward exhaust tongues that could be mistaken for projectiles. Sliding hangar shutters expose dark interiors; running lights announce launches without baking enemy sprites into the boss.

## Timeline and integration contract

Frame numbers below are **one-based**. JSON ranges are **zero-based**. Only `phase_1`, `phase_2`, `phase_3`, and the sustained `beam_fire` may loop. Phase idle frames deliberately remain steady so an idle pulse cannot imitate an attack charge. Other tags play once.

| Tag | Frames | Duration | Intended meaning |
|---|---|---|---|
| `phase_1` | 1–4 | 720 ms | Closed hangars, guns resting |
| `volley_charge` | 5–10 | 600 ms | Both guns build three warning segments |
| `volley_fire` | 11–13 | 180 ms | Red muzzle flash and recoil; shot event on frame 11 |
| `volley_recover` | 14–17 | 520 ms | Barrels return, warning segments extinguish |
| `open_bays` | 18–23 | 780 ms | Shutters slide apart during transition ceasefire |
| `phase_2` | 24–27 | 720 ms | Open hangars, guns resting |
| `launch` | 28–33 | 720 ms | Outward running lights; suggested launch events at 31 and 33 |
| `port_charge` | 34–38 | 600 ms | Only left gun warns |
| `port_fire` | 39–41 | 210 ms | Left amber flash/recoil; shot event on 39 |
| `port_recover` | 42–45 | 520 ms | Left gun resets |
| `starboard_charge` | 46–50 | 600 ms | Only right gun warns |
| `starboard_fire` | 51–53 | 210 ms | Right amber flash/recoil; shot event on 51 |
| `starboard_recover` | 54–57 | 520 ms | Right gun resets |
| `core_transition` | 58–65 | 960 ms | Central armor shutters separate |
| `phase_3` | 66–69 | 720 ms | Aperture open, core remains dim until charging |
| `beam_charge` | 70–77 | 960 ms | Trench fills toward muzzle, converging sparks, white peak |
| `beam_fire` | 78–81 | 320 ms | Flowing muzzle effect; beam begins on 78 |
| `beam_recover` | 82–87 | 840 ms | Beam off, core cools back to dim red |

White is reserved for actual peak charge and discharge, rather than constant phase-three brightness. Runtime should control beam duration separately from its four-frame flow loop. The sprite contains only the muzzle effect; the damaging beam needs its separate combat visual and collision implementation. Recovery communicates weapon downtime, not an implemented damage multiplier or vulnerability window.

New muzzle slices are centered at `(24,80)`, `(104,80)`, and `(64,90)` in sprite coordinates: `port_muzzle`, `starboard_muzzle`, `core_muzzle`. Existing launch-bay slices remain the launch anchors. Existing upper battery slices remain references, not the new lower gun origins. Muzzle flashes recoil with the barrels; these anchors describe their nominal resting positions.

## Exports and validation

The PNG now uses **12 columns and 8 rows**, 128×96 cells, 87 frames, with unused final cells. Read `assets/sprites/bosses/dread_ark_128x96_sheet.json` for frame rectangles, durations, tags and slices; the former twelve-frame horizontal layout is superseded. No current runtime reference to this sheet was found.

Animated previews at 4× nearest-neighbor scale:

- `assets/art/sprite_references/dread_ark/volley.gif`
- `assets/art/sprite_references/dread_ark/bays_and_broadsides.gif`
- `assets/art/sprite_references/dread_ark/central_beam.gif`

Verified all 87 sheet cells against independent source PNG exports, complete non-overlapping coverage by 18 tags, visible frame differences in every action tag, and stable upper silhouette across the timeline. Inspected charge, discharge and beam frames. Gameplay timing, projectile synchronization, full beam continuity and combat readability require the future boss integration; these are not claimed as tested.
