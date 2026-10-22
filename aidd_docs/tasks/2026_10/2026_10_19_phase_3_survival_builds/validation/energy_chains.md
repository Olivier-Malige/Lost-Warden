# Electric cannon chains — 2026-10-21

The maintainer authorized this next checkpoint after moving piercing to the manual plasma beam, explicitly deferring effect balancing. The existing planned `energy_chains` family is delivered ahead of missiles/explosions. Its standalone scope is complete; future explosion coexistence and autonomous-weapon compatibility remain acceptance items for their respective deliveries.

## Playable behavior

`energy_chains` occupies one personal offensive slot and has three ranks. The first accepted main/side-cannon impact can jump to 1/2/3 other targets, with 72/88/104 px range per jump. Each search begins at the last accepted target, chooses the nearest visible eligible group and breaks distance ties by stable spawn identity. Intervening armor/collision surfaces block acquisition. Already accepted groups remain excluded across the root and all children, including overlapping boss surfaces.

Each jump deals 45% of the source's modified pre-critical damage, without additional decay or another DAMAGE multiplier. The initial gun shot retains its normal damage/critical result. Chains are secondary packets with no critical or proc modifiers; they cannot create new chains, piercing or further procs. Shared personal cooldown is 0.5 seconds across compatible weapons, independent of FIRE_RATE and of the partner's cooldown. Plasma/reflected shots remain excluded. These are the plan's prototype numbers, not final balance acceptance.

PlayerHitEffects copies the impact/rank/range/damage and retains its root before the source recycles. Deferred resolution revalidates world, owner and candidates. Leaving a logical boss group excludes its vulnerable overlapping colliders from the outgoing ray; armor still blocks it. Owner DYING/world cancellation retires pending work. Pause freezes requests, cooldowns and visuals. Accepted secondary kills retain player ownership, normal XP/plasma rules and one elimination.

The live catalog contains thirteen entries: seven utilities, three offensive families (side shots, criticals, chains), two rewards and the automatic fallback. The retired cannon-piercing card remains absent. Existing beam piercing is unchanged.

## Art and native presentation

Authored through the Aseprite MCP with Lost Warden 64. `assets/sources/combat/energy_chain.aseprite` has four 48x32 frames, tag `energy_arc`, 60 ms each. The PNG/JSON export is 192x32. Each frame contains P1 at y0-15 and P2 at y16-31: a 32x8 link tile at x0 and a 16x16 endpoint anchor at x32, pivot (8,8). The complete source/export has 780 opaque pixels; every pixel matches the export, alpha is binary and all opaque colors match the palette exactly.

EnergyChain renders the finite accepted path with integer-snapped jagged links, an owner-colored rim, ivory core, animated tile sparks and anchors. Four frames expire after 240 ms. It has no collision or owning target references, at most three links and sixteen global instances; normal two-player cooldown/lifetime bounds are lower. A first native review found the textured links too faint; solid rim/core layers preserve a continuous readable connection.

Maintainer movement follow-up: visual endpoints now follow their accepted enemies through weak references and local impact offsets. The first offset is captured before damage-induced recoil; links, core, sparks and endpoint sprites update together during the animation, including rotations. Removed enemies leave their last known position; surviving junctions keep following. Pause freezes both attachment updates and age. Damage, targets, jump order, ranges and cooldowns are already resolved and never recalculated by this visual tracking. Native `energy_chains_follow_0.webp` and `_2.webp` show the same links following distinct enemy movements; endpoint alignment and unchanged damage are asserted. The cap rejection path now stops processing before its unconstructed visual is freed.

Menu/HUD atlases append column 12, preserving all preceding pixels. `upgrade_icons_64` is 832x128 with 64px cells at x768, owner rows y0/y64; `upgrade_miniatures` is 208x32 with 16px cells at x192, rows y0/y16. Both masters add `Nearest target electric arcs`. The real Nomad fires into a zigzag connecting several targets. Fresh Aseprite source composites equal exports, have binary alpha and exact palette colors.

Inspected native 640x400 captures in `.godot/phase_2_runtime_validation`: `energy_chains_0.webp`, `_2.webp`, `_3.webp`, `energy_chains_choices.webp`, `energy_chains_boss.webp`, `energy_chains_solo.webp`. Solo capture follows a real gun/Area2D contact; co-op/boss captures use controlled accepted-hit setups. Links visibly join accepted targets in both owner colors and stop against the boss's obstructing geometry. Card numbers fit their cells. Focused ICON-PIXEL-LOCK, COMP-SAFE-EDGE and LIGHT-PLAY-SEP score 2/2 in the inspected states. This is not broad visual/performance certification or human co-op balance acceptance.

## Actual checks

Godot 4.7.2, addon-free isolated runtime, separate APPDATA directories:

| Fixture | Result |
| --- | --- |
| `tests/test_energy_chains.gd`, native compatibility renderer | **144 checks PASS** after movement follow-up, clean shutdown |
| `tests/test_upgrade_offers.gd`, headless | **2,133 checks PASS** |
| `tests/test_progression_activation.gd`, native | **76 checks PASS**, clean shutdown |
| Same activation fixture, headless | **67 checks PASS**, existing two-object/one-resource shutdown warning |
| `tests/test_upgrade_selection.gd`, headless | **42 checks PASS** |
| `tests/player/test_player_hit_contract.gd`, headless | **41 checks PASS** |
| `tests/player/test_piercing_and_critical_hits.gd`, headless | **708 checks PASS** |
| `tests/player/test_beam_piercing.gd`, headless | **111 checks PASS** |
| Aseprite source/export, palette, binary alpha and preserved icon columns | **PASS** |
| `git diff --check` | **PASS** |

The chain fixture covers all ranks, actual primary/side contacts, pre-critical math, no repeated group, exact range boundaries, deterministic distance ties, blocked/removed targets, no-target termination, slot/rank limits, emission snapshots and cross-player source reuse, independent cooldowns, FIRE_RATE exclusion, pause before deferred work, owner death/cancellation, boss armor and overlapping parts, normal kill rewards, visual saturation/expiry and five stable visual lifecycle cycles. Native solo and co-op world teardown also runs cleanly.

The capped-offer activation fixture now caps the new completed family before asserting that side-shot rank four is its sole remaining offer. Old seeded economy evidence is historical; it was not rerun against the expanded catalog. No encounter/XP tuning, save-schema change, new audio, commit or push is included. Remaining step-5 solo observations, full build combinations, final performance/economy and human audio/balance acceptance are still pending.

## Explicit source compatibility — 2026-10-22

The maintainer reported lightning recurring on new upgrades. Satellite contacts were the remaining allowed support source; explosion SECONDARY packets already could not recurse. Chains are now explicitly limited to GUN (main/side cannon). PlayerHitSnapshot owns the source/modifier table, filters incompatible combat ranks even in raw packets and rejects unknown source/effect pairs by default. PlayerHitEffects and projectile piercing setup consult that same policy; missile/drone/satellite emitter erase lists are removed.

**165 native chain checks PASS**, including all seven current source kinds, unknown source/effect rejection, independent explosion permission, raw snapshot filtering, main/side physical impacts, ownership, RNG/cooldown, moving anchors and boss behavior. **269 native satellite checks PASS** now expect no lightning or cannon-cooldown consumption from real orbit overlaps. Missile/drone regressions retain their criticals and planned independent effects. Native selection/progression and 93 clean diagnostic documents pass. Future procs must opt into the same policy rather than treating every direct hit as compatible.

## Main cannon only — 2026-10-22

The maintainer further excludes lateral fire. Append SIDE_GUN to the existing kind enum and require an explicit kind at each cannon emitter call. Primary GUN alone allows energy_chains; SIDE_GUN retains direct criticals/explosions and legacy/planned piercing/ricochet compatibility. Snapshot filtering and proc guards continue to consult the central policy, with no local exception list.

**200 native checks PASS**, clean exit. Real P1/P2 side fire at ranks 1 and 4 validates both the ordinary pair and all four inner/outer shots: direct damage is unchanged, no chain/neighbor damage/cooldown is created, then that same volley’s primary shot triggers its chain normally. All eight kinds and unregistered sources are covered. The native card now reads MAIN before jump/range information. Regression captures and 93 clean diagnostic documents confirm integration.

## Independent ordinary-target histories — 2026-10-22

Under the approved expanding-wave plan, chains and explosions may each damage the same ordinary group once. `resolve_hit` and `visited_groups` use explicit secondary channels, with directly hit groups and boss history shared. This is damage stacking, not recursive procs: chain/explosion snapshots still have no critical or modifier capabilities. Main-only source authorization is unchanged. Both orderings against ordinary hulls and boss parts pass the new wave fixture; the existing chain suite passes **200 native checks**, clean exit. See [wave evidence](impact_explosion_wave.md).
