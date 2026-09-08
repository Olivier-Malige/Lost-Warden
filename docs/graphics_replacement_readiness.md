# Graphics Replacement Readiness

Date: 2026-09-08. Scope: the current game and the produced replacement set, not every future roadmap phase.

## Decision

The produced set is sufficient to start a coordinated graphical integration. It is not a drop-in replacement for every current scene, and it is not yet complete for a final graphics replacement. A matching Nomad destruction sequence is now available. The main remaining work is scene integration and visual/collision validation, rather than producing more decorative effects.

## Coverage and Remaining Work

| Area | Evidence | Remaining work |
|---|---|---|
| Nomad flight | `ship_banking_master.aseprite` has 13 idle/banking/return frames and both player exports. | The scene still uses `x_wing.png`, 12×2 frames, and its old animation indices. Map the new poses and pivot deliberately. |
| Nomad death | `nomad_explosion.ase` and its 288×32 sheet provide nine 32×32 destruction frames at 100 ms each. | Connect the dedicated sheet to player death; `player.tscn` still uses the old X-wing atlas. Flight integration remains separate. |
| Ordinary enemies and asteroids | Replacement sheets and sources include idle/rotation, hit, damage where applicable, and explosion/breakup sequences. | Validate visible silhouettes against collisions and particle anchors, including the selected asteroid variant. |
| Elites | All five elite sheets are produced with localized violet markings. | Integrate variants and reconcile the existing runtime elite effect with the accepted source treatment. No new full-hull outline is needed. |
| Grave Carrier and mounted turrets | New 32×64 source has separate turret layers, damaged references and named anchors. Current carrier uses the old 16×32 frame layout; mounted turrets inherit the general turret scene. | Export/reuse turret components as appropriate and adapt scene geometry and animations. This is assembly work, not evidence of a missing concept. |
| Player weapons and shield | Primary/side sheets, five beam tiers and shield idle/reflection frames are present. | Verify atlas regions, charge timing, shield alignment, core brightness and existing glow at gameplay scale. |
| Enemy weapons | Four new projectile sheets are present; current combat scenes still reference small legacy textures without matching flipbook layouts. | Add the correct animation/atlas mapping and check visual size against collision footprints. |
| Dread Ark | Boss phase sheet, three projectile families with impacts, beam and destruction sequence are present. | Integrate in its owning boss phase; weapon bays, anchors and phase timing require runtime checks. |
| Background | Nine parallax planes and editable master are present. | Replace the old two-texture background setup, preserving tiling and reviewing layered contrast/motion. |
| HUD energy icons | New 32×32 exports exist for both players. | Existing energy scenes still apply scale `(3, 1)` in a control with minimum size `(24, 12)`: this creates a 96×32 texture extent and needs layout/scaling review. |
| Temporary pickups | Eight-cell dark-space atlas and layered source now exist; both pickup scenes and fire-rate mapping are updated. | Integrated and headless-tested in this pass; dense gameplay visual review remains. |

## Effects: Enough to Begin

Already available: enemy hit flashes and explosions, asteroid breakup/debris, shield reflection, player reactor/charge particles, player beams, enemy projectile animation, turret projectile impact/explosion, boss projectile impacts and boss destruction. Existing runtime projectile glows, foreground speed particles, screen shake and screen flash provide additional feedback without requiring new PNG sprites.

Useful later, but not prerequisites for replacing the current art:

- Additional impact variants for energy or armored targets; player-shot contacts now emit short gold pixel sparks.
- Further pickup feedback tuning after gameplay review; collected upgrades and plasma now emit colored converging pixel fragments.
- Future XP-orb feedback, level-up ring, upgrade-card feedback and expanded explosion bursts, retained in their roadmap phases.

Future XP shards, upgrade-card icons and new enemy roles remain outside the current replacement. More effects should be added only where playtesting reveals missing feedback; dark-space readability benefits from short, localized light rather than permanent halos.

## Temporary Pickup Redesign

The maintainer explicitly requested this replacement, overriding the earlier temporary-pickup exclusion in the production inventory.

- Source: `assets/sources/pickups/power_up_master.ase`.
- Export: `assets/sprites/pickups/power_up.png`, 128×16, eight 16×16 cells.
- Layers: dark casing, pickup symbol, status light. Static tags match the eight cells.
- Appearance: chamfered blackened-metal module, pale-steel pictogram, sparse functional accent. No red or magenta pickup accent.
- Display: now 2×, so each cell still occupies 32×32 pixels. Both collision shapes, movement, upgrade weights/ranks and charge amounts are unchanged.

| Zero-based frame | Meaning | Accent | Symbol |
|---:|---|---|---|
| 0 | Damage | Neon Gold | Heavy projectile with a plus sign |
| 1 | Speed | Ice Blue | Boot with motion lines |
| 2 | Energy/repair | Pickup Green | Medical cross |
| 3 | Side shots | Neon Gold | Three projectiles in a fan |
| 4 | Shield | Ice Blue | Shield outline |
| 5 | Beam, retained legacy animation slot | Plasma Cyan | Focused beam |
| 6 | Fire rate | Neon Gold | Three successive projectiles |
| 7 | Plasma cell | Plasma Cyan | Battery with two charge bars |

The six active direct-upgrade definitions use frames 0–4 and 6. Frame 5 remains available for the existing beam animation but is not added to the upgrade table. The plasma scene now uses frame 7. Fire rate gets its own `fireRate` animation instead of borrowing the damage icon and tinting the entire sprite.

Validation:

- Eight distinct cells, exact 128×16 export, and visible RGB colors confined to Lost Warden 24.
- Godot 4.7.2 headless scene tests in an isolated project copy passed for all six upgrades: animation mapping, 16×16 frame size, 2× display, untinted authored colors, upgrade delivery, collection event and collision shutdown.
- Plasma passed its distinct frame, 12.5 charge amount, single-collection guard, sprite hiding and collision shutdown checks.
- Sources and enlarged comparison inspected. Static icon review: palette-role consistency 2/2, shared grid/material 2/2, glyph differentiation requires user review, dense moving-background readability unverified. The latter requires in-game observation, not a headless assertion.
- No commit or full-scene graphical integration was performed in this pass.

Preview: `assets/art/sprite_references/dark_space_pickups.png` shows the revised icons in atlas order. Editable preview: `assets/sources/art/dark_space_pickups.ase`.


## Pickup Legibility Revision

The maintainer found the first 8×8 symbols insufficiently representative. The master was redrawn at 16×16 rather than enlarged from the old glyphs. The casing remains dark, but each function now uses a recognizable object or action: heavy projectile plus, moving boot, repair cross, spread volley, shield, focused beam, repeated projectiles, and battery. Scene sprite scale changes from 4× to 2× preserve the 32×32 screen footprint and existing collisions. Atlas order, animation names, pickup behavior, and accent roles remain unchanged.

The higher logical resolution is a deliberate pickup-specific readability exception. Recognition in dense moving gameplay remains subject to user playtesting; enlarging the preview alone is not proof of readability at native display size.

## Explosion Art Revision

The requested stronger explosions now use brief ivory/gold cores, orange and ember lobes, broken shock rings, and cooling metal fragments. All ten ordinary/elite enemy sheets have revised explosion cells. The carrier uses staggered module bursts; the Dread Ark uses wing detonations followed by a larger core rupture. The new Nomad sequence includes recognizable wing and nose fragments.

Native sources and horizontal PNG exports are synchronized. Existing enemy and boss frame counts, tag ranges and frame durations were checked against the pre-explosion backup. Pixel comparisons passed for all non-explosion frames in the ten enemy sheets; atlas dimensions are unchanged. Nomad and boss final frames are transparent. No runtime behavior or collision changes were made in this art pass, and full gameplay visual validation remains outstanding. Existing scenes referencing the revised enemy sheets receive those pixels automatically; the new Nomad, carrier layout and boss integration remain as listed above.

Preview: `assets/art/sprite_references/dark_space_explosions.gif` (fighter, Nomad, carrier, boss, left to right). Editable preview: `assets/sources/art/dark_space_explosions.ase`.

## Runtime Impact and Collection Feedback — 2026-09-08

`scenes/effects/combat_feedback.gd` draws transient pixel primitives directly in Godot; no raster source or texture export is involved. Player-shot contacts emit seven gold sparks and a brief ivory core (0.22 seconds). Upgrade and plasma collection emit six fragments converging on the collecting player (0.38 seconds), using the pickup accent: gold, ice blue, green or cyan. Effects are siblings of their emitter, survive projectile recycling/pickup removal, follow a moving collector and expire safely if it disappears. A 64-effect cap bounds simultaneous nodes.

The pickup handler now ignores duplicate collection callbacks and stops movement after collection. Pooled shots ignore subsequent contact callbacks. Damage values, piercing behavior, upgrade delivery and collision shapes are unchanged. Headless Godot 4.7.2 checks passed for all six upgrades and plasma, target tracking and deletion, active-effect cap and cleanup, projectile duplicate suppression, deferred pool parking and piercing behavior. Checks ran in isolated copies; visual tuning in full gameplay remains outstanding.
