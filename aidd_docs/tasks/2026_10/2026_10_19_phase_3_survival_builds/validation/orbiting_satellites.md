# Step 10 — orbiting satellites

Historical checkpoint: the [2026-10-28 three-satellite growth revision](../../2026_10_28_satellite_growth/validation.md) supersedes the rank-based counts, damage and fixed contact size below. Later steel art, orbit/spin periods and scripted sprite rotation remain in use.

Implemented and verified on 2026-10-21 with Godot 4.7.2. The maintainer accepted and requested publication of step 9 before authorizing this checkpoint. Commit `f20c148` is verified on both local HEAD and `origin/codex/phase-3-survival-builds`; this new satellite checkpoint remains local for playtest.

## Playable behavior

- One offensive family, three ranks: one / two / three capacitors spaced evenly on a 32px orbit, with a fixed 2.5-second period. Ranking preserves phase. P1 starts at zero radians, P2 at PI.
- Each orbiter has a 4px contact radius, no collision layer and a mask limited to enemy/asteroid surfaces. It observes vulnerable overlaps without blocking bullets, reflecting shots or changing the player's bounds/collision. Circle construction and removal are deferred outside physics callbacks.
- Base direct contact damage is 1 / 1.25 / 1.5, multiplied by common DAMAGE exactly once. The shared owner/group cooldown is 0.50 seconds; FIRE_RATE scales it by manual delay / 0.20, minimum 0.6. Orbit speed is unchanged.
- All of one owner's satellites share each logical target's cooldown. Separate owners may contact the same group independently. Leaving/re-entering does not reset the cooldown; expired, destroyed or freed groups release their weak records.
- Ready contacts sort by stable group/surface identity and orbiter index. Known rejected/inactive/armored surfaces are filtered before drawing critical RNG; only accepted direct contacts start cooldowns. One root covers one accepted contact, and overlapping boss parts share one group.
- Contact criticals retain x2 direct damage and their owner's combat stream. Piercing/ricochet are stripped. The completed energy-chain family remains compatible with contacts under the approved contract; secondary effects cannot recurse. Existing drone/missile lightning exclusions remain in force.
- Contact flashes are finite (four 50ms frames). Pause freezes orbit, contact timers and flashes. DYING disables monitoring/shapes deferred and removes only that owner's support; held-input reset preserves it. World teardown cancels pending construction.
- The completed family is registered in the 16-entry live catalog with native cards and miniatures. Long card titles use 10px when 12px would overlap the rank label.

## Verification

| Check | Result |
| --- | --- |
| `tests/player/test_orbiting_satellites.gd`, native OpenGL | **269 checks, zero failures**, clean exit |
| Upgrade offers | **2,133 checks**, pass |
| Progression activation | **76 native checks**, pass |
| Escort drones | **460 native checks**, pass |
| Upgrade selection | **48 native checks**, pass |
| Energy chains | **144 native checks**, pass |
| Accepted-hit contract | **42 native checks**, pass |
| Micro-missiles | **458 native checks**, pass |
| Fresh editor language-server diagnostics | **86 game scripts + five combat tests**, zero errors/warnings |
| Aseprite composite / runtime PNG equality | Zero differing pixels for satellite, menu and miniature pairs |
| Palette / alpha | Exact Lost Warden 64 colors and binary alpha for all new PNGs |
| Existing atlas columns | First fifteen columns pixel-identical to `f20c148` |
| `git diff --check` | Pass |

The satellite fixture exercises all ranks, exact radius/spacing/phase and full orbit duration, maximum DAMAGE/FIRE_RATE, real continuous overlaps and crossing/re-entry, simultaneous orbiters, independent P1/P2 cooldowns, both owners' seeded critical replays with reversed insertion order, rejected boss/armor contacts, one critical draw across overlapping boss parts, completed-chain recursion limits, enemy-shot passage, kill/XP credit, pause, DYING from an actual `area_entered` callback and repeated world teardown with/without pending construction.

An initial kill fixture authored invalid fractional enemy max health and was corrected to a valid one-HP target before final native validation. The final logs are clean, including shutdown.

## Art and native inspection

The editable source has eight 16x256 frames, exporting a 128x256 sheet with matching JSON. Runtime cells are 16x16 at pivot (8,8). Rows 0-7 are P1, rows 8-15 P2, with eight outward orientations in 45-degree steps. Frames 0-3 are `orbit` at 80ms; 4-7 are `contact` at 50ms. The visible metal core agrees with the 4px contact radius; the short contact sparks are decorative.

Card/miniature sources append column 15 at x960 / x240, producing 1024x128 / 256x32 atlases. The illustrations combine real Nomad art with three orbiters and subdued orbit marks, retaining transparent margins and all prior pixels.

Ignored captures in `.godot/phase_2_runtime_validation/` were inspected: `satellites_{solo,coop,wide}_{0,1,2,3}.webp`, `satellites_edges_{solo,coop,wide}.webp` and `satellites_choices_{solo,coop,wide}.webp`. A real Razor Wing hunter crosses the orbit and receives direct contact feedback; team rows, native pixel orientation and card/rank separation are visible. At the extreme movement boundaries part of the fixed-radius orbit can naturally extend beyond the viewport or beneath the HUD; player bounds and the contracted radius remain unchanged.

Stop for maintainer playtest. Effect balancing, two remaining solo XP observations, human co-op balance acceptance and dedicated selection audio remain deferred. Step 11 impact explosions are next; no explosion, ricochet or permanent progression work is included here.

## Chain compatibility correction — 2026-10-22

The maintainer's playtest supersedes the original satellite-chain contract: contacts retain direct criticals and impact explosions, but cannot trigger electric chains. The centralized PlayerHitSnapshot policy strips the chain modifier before contact resolution and the proc queue uses the same allowlist. **269 native checks PASS** with no chain visual, no secondary neighbor damage and no chain-cooldown consumption from a real satellite overlap. The contact geometry, cadence, ownership and pause/death behavior remain unchanged.

## Steel satellite appearance and motion revision — 2026-10-22

The latest approved revision supersedes the 2.5-second outward-facing art above. The maintainer accepted explosions for now and requested metallic spiked orbiters with faster orbits and independent spin. During implementation they rejected the first flat cross-like draft; the delivered source is the refined replacement.

- Orbit period: **1.25 seconds**, every rank. Independent body spin: **0.625 seconds**, clockwise, with a deterministic offset for each orbiter. Phase changes are independent of FIRE_RATE. Both phases persist across rank changes and pause freezes orbit, spin, animation, flashes and contact timers.
- `UpgradeDefinition.spin_period` is a resource field and offer value. Satellite data rejects zero, negative, infinite or NaN periods; other families retain their zero default.
- Native 16x16 art has a beveled dark steel core, four thin tapered spikes and small asymmetric team inserts. The radius-four core hitbox, orbit radius 32, counts 1/2/3, damage 1/1.25/1.5 and shared 0.50-second base cooldown remain unchanged. Tips are decorative. Eight baked orientations avoid filtered runtime rotation.
- The Aseprite MCP edits and exports the source. Editable layers separate steel hulls, player inserts and accepted-contact glints/sparks. Team rows, eight animation frames and `orbit` 80ms / `contact` 50ms tags remain unchanged. Both UI masters now use the same steel silhouette in column 15; the real Nomad is retained on the card. Other columns are pixel-identical to the incoming working tree, including explosions.

| Final check | Result |
| --- | --- |
| Native satellite fixture after refined art | **364 checks, zero failures**, clean exit |
| Headless satellite mechanics before native presentation | **289 checks, zero failures** |
| Native expanding explosions, including real satellite-triggered blast | **263 checks, zero failures** |
| Native main-only energy chains | **200 checks, zero failures** |
| Native upgrade selection | **48 checks, zero failures** |
| Native upgrade offers | **2,133 checks, zero failures** |
| Editor diagnostics | **87 game scripts + six fixtures, 93 documents, zero errors/warnings** |
| Three Aseprite composite/runtime pairs | Zero visible differing pixels |
| Palette, alpha, directions, tags and durations | Exact Lost Warden 64, binary alpha, eight distinct directions, unchanged metadata |
| All non-satellite atlas columns | Pixel-identical to incoming working tree |

The fixture validates both periods at all three ranks, phase preservation, offset blue-team orientations, maximum FIRE_RATE independence, pause, safe callback death and teardown. Six actual moving enemies (one for every owner/rank pair) use their real 20x18 hulls at 80px/s and normal physics overlaps; HP loss equals the accepted direct-hit count times authored rank damage. Existing seeded critical, boss-group, chain exclusion, projectile passage and kill-credit checks remain. The explosion regression independently confirms contact-triggered splash.

The native fixture also compares the imported texture with the current raw export to reject stale Godot caches. After a fresh editor import, native solo/co-op/wide sequences capture 15 states over approximately one second, with a real moving Razor Wing using its normal hull; contact HP loss is asserted. Captures `satellites_{solo,coop,wide}_{0..14}.webp`, edge states and selection cards live in the ignored isolated project. The refined sequence and cards were inspected at native size and enlarged nearest-neighbor for material/readability review. A reconstructed native sequence GIF/contact sheet is under `.godot/satellite_qa/`. No gameplay balancing beyond the approved orbit speed, new audio, ricochet, commit or push is included. Stop for maintainer playtest.

## One team sprite with scripted rotation — 2026-10-22

The maintainer requested replacing the eight baked orientations with one canonical hull per player, rotated in script. This supersedes the eight-orientation presentation above. The controller now rotates only each `Sprite2D` using its independent spin angle; the Area2D and its radius-four circle remain unrotated. Rotation is continuous rather than quantized into 45-degree rows. Nearest-neighbor texture filtering is retained.

The Aseprite MCP keeps the existing refined artwork pixel-identically: old direction-zero P1/P2 cells become rows 0/1. The source is now eight **16x32** animation frames, exported as **128x32** PNG/JSON, with three editable layers. Runtime uses `hframes=8`, `vframes=2`, frame `team * 8 + animation_frame` and scripted `Sprite2D.rotation`. The existing `orbit` 0-3/80ms and `contact` 4-7/50ms tags remain. This is one orientation per player, with finite reflection/contact animation frames. Card and miniature illustrations remain unchanged.

The resource periods stay 1.25 seconds per orbit and 0.625 seconds per spin. Counts, damage, cooldowns, contact radius, target policy and source compatibility are unchanged. The satellite fixture checks exact continuous sprite angles, both team rows, unrotated colliders, pause and every existing physical contact/lifecycle case. Final native satellite **364 checks** and explosion **263 checks PASS**, with clean exits. Editor diagnostics: **93 documents, zero errors/warnings**. Canonical old/new cells are pixel-identical; source/export parity, exact palette/binary alpha and animation metadata pass. Updated native solo/co-op/wide sequences and menus are inspected. No commit/push or next family is included.

## Selection illustration follow-up — 2026-10-22

At the maintainer's request, both satellite selection illustrations now emphasize the current canonical steel hull: a larger foreground satellite, real Nomad and two orbiting companions with small movement marks. The Aseprite MCP edits the existing 64px UI source column and exports the runtime PNG. Gameplay sprites, miniatures, combat and menu layout remain unchanged. Other atlas columns are pixel-identical to the incoming working tree. Source/export visible parity and exact Lost Warden 64/binary-alpha checks pass. Native selection **48 checks PASS**, clean exit; focused solo/co-op captures `satellite_selection_{solo,coop}.webp` in the isolated project are inspected. No commit/push is requested.

### Selection foreground size adjustment — 2026-10-22

The maintainer found the foreground satellite too large. The Aseprite card now uses the canonical 16px hull at native size, matching the other two satellites, instead of the previous 32px enlargement. Its small rotation mark is resized accordingly; both team colors are updated. Source/export parity, exact palette/binary alpha and preservation of every other atlas column pass. This supersedes the larger foreground composition above.
