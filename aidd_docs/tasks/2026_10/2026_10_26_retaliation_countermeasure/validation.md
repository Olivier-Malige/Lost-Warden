# Retaliation countermeasure validation — 2026-10-26

Historical checkpoint before the [projectile/contact role split](../2026_10_26_defense_role_split/validation.md). Use that later validation for the current sphere behavior, icons and effects.

Implemented the [approved behavior](plan.md), including the maintainer's contact-only correction. Damage sources explicitly identify enemy body contact before vitals change. Only a direct enemy collision can trigger the ready pulse; projectiles (including lethal ones), continuous beams, small asteroids and large asteroids preserve its charge. After a collision activates the pulse, the 0.6-second protection still covers all incoming damage. Shield rupture preserves the pulse. Cooldown rank changes preserve completed recharge percentage. The existing artwork is scaled to the new radius, reaches its largest ring at the expansion boundary, holds through the active interval, and only then switches to inactive fragments. The selection card displays the contact trigger, protection, damage, radius and the correct rank cooldown.

Provisional rank values: damage 4/6/8, radius 64/80/96 pixels and recharge 12/10/8 seconds. Protection is 0.6 seconds at every rank; wave expansion/active/visual boundaries are 0.20/0.35/0.60 seconds. Final balance still requires maintainer playtest.

## Verification

Godot 4.7.2, existing addon-free `.godot/phase_2_runtime_validation/` project with junctions to current sources. Each suite uses its own ignored APPDATA directory, isolating personal save data. All listed suites exit successfully with zero failed checks.

| Suite | Checks |
| --- | ---: |
| Defensive pack, headless | 263 |
| Defensive pack, native OpenGL | 350 |
| Guard blades, headless | 234 |
| Player hit contract, headless | 41 |
| Hull contacts, headless | 75 |
| Hull contacts, native OpenGL | 81 |
| Boss destructible parts, headless | 73 |
| Upgrade offers, headless | 4,531 |
| Upgrade selection, headless | 65 |
| Impact explosions, headless | 203 |

The contact-only correction reran both defensive modes, hull contacts and the player hit contract. The subsequent intermittent-contact fix reran both defensive modes, both hull-contact modes, the player hit contract and boss destructible parts. The remaining rows record the preceding countermeasure regressions.

The [collision investigation](collision_debug.md) reproduces a brief real overlap lost between the physics callback and the post-movement query, with no pulse, a ready pulse and a cooling pulse. All three behavior assertions fail before the fix and pass afterward. Physics-confirmed unshielded body contacts now share the existing defense path with sustained-contact polling. Additional assertions preserve masks, shield charge cadence and actual boss-part identity; the protection duration and balance values are unchanged. Both final native stderr logs are empty.

The defensive suite covers lethal enemy-contact prevention; non-triggering simultaneous and lethal real projectile callbacks; non-triggering actual boss beam ticks and both asteroid families; actual enemy body contact; projectile and beam immunity after contact activation; the full protection window and damage after expiry; shield-first ordering; ordinary grace and reactive armor; per-rank reach and damage; common DAMAGE exactly once; armor occlusion; reflected-shot preservation; clearing late arrivals during the active hold; inactive fragments; visual saturation; co-op ownership; recharge rank changes; pause; death during accepted-hit callbacks; and repeated world teardown without residual nodes or hit roots.

Example headless command, after setting APPDATA to an isolated directory:

```powershell
& C:/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path .godot/phase_2_runtime_validation --script res://tests/player/test_defensive_pack.gd
```

The native run uses the same suite with `--windowed --resolution 640x400 --audio-driver Dummy` instead of `--headless`. Its final stderr log is empty. Native solo, co-op and wide layouts produce ignored `defense_*` WebP captures in the validation project, including impact, expanding wave, active ring, recharge, return, both player palettes and upgrade choices.

Focused visual checks: LIGHT-PART-OCCLUDE 2/2 (wave and protection do not cover HUD); LIGHT-HIT-SCALE 2/2 (the larger retaliation reads distinctly from the small protection ring); COLOR-FX 2/2 (existing red/blue owner palettes remain consistent); ICON-STATE 2/2 (ready brackets, temporary protection ring and cooling absence are distinct). Native upgrade cards show the complete protection/reach/recharge copy within the existing two-line space.

`git diff --check` passes. The pre-existing local MCP activation edits in `project.godot` are untouched. No commit or publication was requested. Next: maintainer playtest of a pulse-only build and a sphere-plus-pulse build before further balancing.
