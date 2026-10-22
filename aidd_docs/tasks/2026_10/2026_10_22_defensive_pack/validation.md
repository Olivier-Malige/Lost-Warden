# Defensive pack implementation evidence

Verified 2026-10-22. Scope is the maintainer-approved reflector sphere, reactive armor and retaliation pulse, followed by a playtest before ricochet. No commit or publication is requested.

## Delivered behavior

- `shield` retains its existing ID and enum ordinal 4, now a three-rank utility family rather than a repeatable reward. Capacities 3/5/7 and recharge 8/6/4 seconds are resource-authored. Armor and retaliation append effect ordinals 19/20; the live catalog has 19 entries. All three families share the existing three utility slots. Energy is still the repeatable repair reward; no save-format or permanent-progression change is introduced.
- PlayerDefenses owns incoming projectile/body/beam handling. Its centered radius-20 shape queries actual hitboxes, including offsets/rotation. The previous charge-based blanket projectile immunity and duplicate enemy/player body callbacks are removed. Blocked contacts cause no automatic ram damage. Continued body/core overlap remains dangerous when protection falls, at ordinary injury-grace cadence.
- A distinct projectile consumes one charge and reverses its original velocity/damage once. Overlapping co-op fields resolve a single owner before hull callbacks, with distance then player-ID ordering. Pooled spawn sequence stabilizes simultaneous shot ordering. Reflection preserves source credit and its fail-closed modifier policy. Projectiles return to the pool safely; deferred parking now uses WeakRef so freeing a source before parking cannot produce an invalid-argument callback.
- Body cooldown is 0.5 seconds per owner/logical actor, shared by all boss pieces. Lasers consume a charge at the existing 0.35-second cadence, then damage hull energy while the sphere is down. The final charge absorbs its complete impact. Partial charges never regenerate. Rank increases retain spent charges or recharge progress; a returning field immediately processes threats already inside it.
- Armor extends ordinary post-injury grace to 1.25/1.50/1.75 seconds. The original one-second slowdown/hit color is kept separately. Continuous hazards still bypass ordinary grace.
- Retaliation triggers on rupture or a nonfatal injury, including without shield ownership, at most once every four seconds per owner. It snapshots position, rank and common damage multiplier before deferred creation. Damage is 2/3/4 times common DAMAGE once; radius is 32/40/48. A secondary hit root prevents crits and recursive modifiers, reaches each ordinary hull once and one piece per boss. Explicit armor blocks hull damage and shot clearing. The expanding query and visible front use the same physics age: 25% initial radius, full at 120ms, active through 160ms, inactive fragments through 320ms. Unreflected hostile shots are cleared; reflected shots and continuous beams remain.
- Pause freezes all state. Death cancels pending/active/cooling pulses, root leases, charges and recharge. Weak references release actors and effects through teardown. The four-visual pulse budget never limits gameplay damage.

## Interfaces and presentation

`Events.defense_state_changed(player_id, snapshot)` carries alive/rank/charges/maximum/recharge/grace/pulse-cooldown state. HUD uses the event, with a compact SHIELD current/maximum label or recharge bar below plasma. The full debug inspector includes the defensive timers. Debug upgrades respect utility capacity and never restore unacquired charges.

Original Aseprite MCP sources/exports:

| Asset | Mapping |
| --- | --- |
| Reflector sphere | Eight 48x96 source frames; 384x96 PNG/JSON; native 48px cells, pivot (24,24), P1/P2 rows, idle 0-3, impact 4-5, rupture 6, return 7 |
| Retaliation pulse | Eight 128x768 source frames; 1024x768 PNG/JSON; native 128px cells, pivot (64,64), P1 ranks 1-3 then P2 ranks 1-3; active_wave 0-3 and cooling_fragments 4-7, 40ms frames |
| Selection cards | 1216x128 atlas, 19 columns; shield replaces column 6, armor/pulse append columns 17/18 |
| Build miniatures | 304x32 atlas, same columns and two player rows |

All four source composites and exports have zero visible differing pixels, exact Lost Warden 64 colors and binary alpha. Every incoming non-shield atlas column is pixel-identical; the latest satellite card revision is retained. The sphere interior stays clear. Existing throwback audio is retained with bounded simultaneous playback; optional empty break/return audio nodes are ready for supplied sounds.

## Verification results

| Check | Result |
| --- | --- |
| Defensive pack, native | **292**, PASS, clean exit |
| Expanding explosions, native | **263**, PASS, clean exit |
| Orbiting satellites, native | **364**, PASS, clean exit |
| Accepted-hit contract, native | **42**, PASS, clean exit |
| Electric chains, native | **200**, PASS, clean exit |
| Micro-missiles, native | **458**, PASS, clean exit |
| Escort drones, native | **460**, PASS, clean exit |
| Upgrade offers, native | **3,173**, PASS, clean exit |
| Upgrade selection, native | **48**, PASS, clean exit |
| Progression activation, native | **76**, PASS, clean exit |
| Boss parts, native | **73**, PASS, clean exit |
| Boss projectile presentation, native | **52**, PASS, clean exit |
| Continuous boss beams, native | **22**, PASS, clean exit |
| Piercing beam, native | **118**, PASS, clean exit |
| Focused reflector regression, native | **79**, PASS, clean exit |
| Alpha 9 regression, native | **130**, PASS, clean exit |
| Foundation collision alignment, native | **PASS**, PASS, clean exit |
| Editor language-server diagnostics | **89 game scripts + 13 fixtures, 102 documents, zero errors/warnings** |
| Aseprite source/export, palette and alpha | PASS for all four pairs |
| Unrelated atlas columns | Pixel-identical |
| git diff --check | PASS |

The defensive fixture measures actual HP and charges for all ranks, simultaneous callbacks/overflow, outside rejection, reflection/pool reuse and owner credit, overlapping co-op fields, rank changes during active/recharge state, real body overlaps/reentry and an offset asteroid hitbox, continuous beams, armor timing, six aligned wave victims, entry/reentry/late entry, occluding armor, boss-piece exclusion, independent owner pulses, ten waves under a four-visual cap, paused pending creation, death during accepted-hit callbacks and repeated world teardown. Native cases additionally cover real simultaneous incoming callbacks, red/blue waves with visible victims, returning fields with existing body contacts, HUD recharge/return and all three selection cards.

Native captures in the ignored isolated project are `defense_{solo,coop,wide}_{ready,impact,wave_0..4,recharge,return,choices}.webp` plus `defense_{coop,wide}_blue_{0..3}.webp`. Ready, expansion, inactive fragments, recharge, return and selection states were inspected. Earlier explosion/orbital presentation fixtures had wall-clock assumptions; their assertions now inspect live effects before expiry and use controlled native movement steps. Final reruns are clean with 263/364 checks.

## Existing out-of-scope validation limitation

The unrestricted historical collision sweep still reports 38 assertions on older hunter/interceptor/projectile/pickup bounds and obsolete pickup animation frames. A harness built from the committed sweep before its shield block produces the exact same 66 error messages on these unchanged assets. The foundation-only collision sweep, including the new sphere, passes. No unrelated collider/art redesign is included. An initial headless progression fixture retained its known two-object/one-resource shutdown warning; its authoritative native rerun is clean.

Stop for maintainer playtest of the close-range defensive build. Broad density/balance acceptance, dedicated supplied audio and ricochet remain pending.
