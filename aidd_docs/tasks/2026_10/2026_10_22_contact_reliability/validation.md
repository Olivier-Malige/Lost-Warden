# Hull contacts and three-offensive build validation

Verified locally on 2026-10-22 using Godot 4.7.2, native OpenGL Compatibility rendering and an addon-free isolated project. Stop for maintainer playtest before ricochet. No commit or publication requested.

## Reproductions and fixes

The first native `test_hull_contacts.gd` run produced **three failures out of five checks**:

1. The real hunter's nose reached the player's central hitbox without costing energy. The inherited 20x18 drone rectangle did not cover its longer 26x27 visible hull.
2. Steering rotated the hunter sprite/reactors but left its collision footprint stationary.
3. After the last body charge absorbed its impact, the same actor could overlap the exposed hull without damage for the shield's remaining half-second contact cooldown.

The hunter now overrides the inherited shape with a convex native hull (nose at y=13, shoulder width 24, rear y=-10). Sprite and collider share its chase heading. The base drone and all other enemy shapes/art are preserved. The player's 16x16 core at (0,-2) is unchanged.

Body cooldown only gates shield charge consumption. It does not gate an unshielded hull query. A logical actor is still considered once per tick, the impact consuming the final charge is fully absorbed, and continuing overlap can wound on the next physics tick subject to ordinary injury grace. No automatic ram damage is inflicted on enemies.

The full geometry fixture now excludes inherited hunter banking clips that its heading-based controller never plays. Its active frame-zero hull remains checked; native real-body tests cover five headings, nose contact and actual energy loss. This avoids judging the new heading-aligned hull against unused inherited poses.

## Build and UI behavior

Progression defaults and the live resource specify **three offensive and three utility families**. Existing acquisition/offer eligibility enforces the capacity; owned families can rank up and are never replaced. Crits, chains and explosions retain their offensive category. The primary cannon and manual plasma signature remain outside these slots.

Selection panels and HUD read both capacities from the detached build snapshot, falling back to the same progression resource for presentation-only snapshots. Utility labels move with the offensive group width. Both players retain personal builds. Debug side-shot/max actions cannot introduce a fourth offensive family. All 35 possible three-family combinations from the seven current offensive families are checked against fourth-family acquisition and offers.

## Verification

| Native fixture | Checks | Result |
| --- | ---: | --- |
| Hull contacts and live/debug/co-op capacities | 63 | PASS |
| Defensive pack | 292 | PASS |
| Upgrade offers | 3,515 | PASS |
| Upgrade selection | 51 | PASS |
| Progression activation / HUD | 80 | PASS |
| Expanding explosions | 263 | PASS |
| Orbiting satellites | 364 | PASS |
| Micro-missiles | 458 | PASS |
| Boss parts | 73 | PASS |
| Accepted-hit contract | 42 | PASS |
| Electric chains | 200 | PASS |
| **Total** | **5,401** | **Zero failures; clean native logs** |
| Targeted foundation collision alignment | — | PASS |
| Fresh GDScript diagnostics | 104 documents | Zero errors/warnings |

The contact fixture measures actual energy and unchanged enemy health: front/side/diagonal crossings of real drone, hunter and interceptor shapes at base/max player speeds (180/240 per axis), hunter nose contacts at five headings, safe grazing, sustained contact, exit/reentry, armor grace separated from slowdown, pause/death, shield rupture/return, rotated asteroid and real boss overlap. The ordinary defensive fixture independently covers lasers, reflection, pulse damage, pooling, saturation and lifecycle handling.

Native frames `contact_native_00/08/12/16/24.webp` show the hunter moving through its real Enemy physics update at 175 units/s: energy is 12 before contact, then 11 during/after the crossing. Solo/co-op/wide selection and gameplay HUD captures show three slots in each category. The first/impact/exit frames and cooperative selection layout were inspected.

Evidence logs are ignored under `.godot/defense_qa/contact_*.log`; diagnostic results are `.godot/console_qa/contact_diagnostics.json`. Captures are in the ignored isolated project. Production sprites, combat values and movement speeds are unchanged by this revision.

## Remaining historical geometry failures

The unrestricted sweep remains red on **31 preexisting assertions**, producing 59 engine/error lines including obsolete pickup frame indices. Compared with the prior recorded sweep, seven hunter body-coverage failures disappear and **no new error messages are added**. Remaining reports concern legacy interceptor/tie bounds, projectile coverage and retired pickup animation/art bounds. These are separate from the reproduced missed core contacts and are not reported as passing.

Start a fresh run to evaluate the reduced build capacity. Broad balancing and ricochet remain pending.
