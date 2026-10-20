# Phase 3 delivery contract

Planning checkpoint: 2026-10-19; preview approved and implementation requested 2026-10-20. The maintainer subsequently authorized delivery through a first playable version. Steps 1-4 are complete: production documentation, progression/loadout/offer models, native paused selection and atomic XP/foundation activation with paired art. Steps 5-14 remain pending. The concise gameplay roadmap controls delivery order; this contract specifies Phase 3 only. The playable checkpoint is ready for maintainer review; no commit is authorized.

The maintainer approved the silent interactive visual preview with **Arsenal déployé** selected. This preview does not complete a numbered delivery step. The maintainer will provide all music and sound effects; no selection audio files have been supplied yet. Step 1 production references are [art_audio_inventory.md](art_audio_inventory.md) and [selection_audio_brief.md](selection_audio_brief.md).

## Confirmed product decisions

- Borrow the XP, paused choices, growing power and build synergies of Vampire Survivors / Megabonk while retaining the existing shmup controls.
- Each living player has four offensive family slots and three utility family slots. Acquiring a new family consumes one slot; increasing its rank consumes none. No replacement during a run.
- Utilities are speed, damage, fire rate, XP attraction, plasma reserve and plasma recovery. Offensives are side shots and the eight new effects below. Repair, shield charges and fallback score consume no slots.
- XP is shared in co-op, choices and equipment are personal. A run ends only after all players die. Human co-op balance acceptance remains deferred until after the power-up and balance rework; verify technical co-op behavior throughout Phase 3.
- Nomad starts with its current primary cannon and its manual secondary signature plasma beam, outside the four offensive slots. Preserve zero initial charge, base capacity 100, activation at 10, drain 20/second and full-reserve overdrive. The maintainer's charge upgrades below can expand personal capacity to 175 and cell recovery to x1.75. No beam unlock card, automatic beam or free permanent beam.
- Future ships may have different signatures. Ship selection, ShipDefinition, unlocks, permanent progression, save-schema additions, rarity and weapon evolution remain outside this phase.
- New weapon sprites, XP/UI art and the selection opening presentation belong to Phase 3. General enemy effects and broad shader polish remain Phase 5.
- Mechanics and delivery boundaries are specified here. Numerical combat/XP values are proposed prototype defaults to measure, not already accepted balance results. Revise this contract explicitly when measurements justify a change.

## Current implementation and ownership

- `RunRandom` already owns independent encounter, enemy, drop and offer RNG streams. `PlayerLoadout` owns current temporary ranks; `PlayerWeapons` spawns manual gun shots. Extend them instead of adding autoloads.
- A pure `RunProgression` model owns shared XP, thresholds and queued selection levels. A world-owned `ProgressionController` coordinates that model, registered live players, drops, offers and selection requests. Destroying the world cancels its pending operations.
- `UpgradeDefinition` gains display name, description, icon, category, repeatable flag and authored rank values. Keep existing enum ordinals; append new effects. Store personal acquired ranks by stable upgrade ID, retaining adapters for existing debug/HUD consumers until migration is complete.
- `PlayerLoadout` owns slot eligibility and derived stats. The UI receives immutable offer/build snapshots through `Events`; it never reads or mutates player nodes.
- Main remains the single owner of tree pause: transition, menu, inspector and level-selection reasons combine. No new pause framework or autoload. Closing any overlay must preserve other active pause reasons.
- Keep new models/catalogs detached from live direct pickups during steps 1-3. Step 4 is one atomic activation of XP, rewards, ranks, HUD and selection. Only fully implemented effects appear in the active offer catalog.
- Planned shared paths are data/progression/run_progression.gd and progression_config.gd/.tres; scenes/progression/progression_controller.gd, xp_orb.gd/.tscn and xp_orb_pool.gd; scenes/ui/upgrade_selection.gd/.tscn and upgrade_selection_audio.gd. Combat shares scenes/combat/player_hit_snapshot.gd, player_hit_effects.gd and combat_targeting.gd. Start progression explicitly after the world's run-seed reset and player registration, not from child-ready callbacks consuming a previous seed.

## Progression and offers

Start at level 1, zero XP. The cost leaving level L is `round(10 * pow(1.28, L - 1))`. Consume thresholds while retaining excess; record each earned selection level in FIFO order. Generate the next level's offers only after both living participants have resolved the previous level.

Open selection deferred after physics. Snapshot only players in ACTIVE/HIT states; DYING/DEAD players are ineligible even before their delayed death event. If no eligible player exists, do not acquire selection pause: let death/game-over complete. Freeze combat, director clocks, plasma drain, projectiles, pickups and proc timers during selection.

Offer policy:

1. Build A from acquired families below maximum rank, N from unacquired families with a free slot, and C from applicable repair/shield rewards.
2. When A and N are both nonempty, reserve one weighted unique pick from each, then fill to three from remaining A/N/C. At the first selection, reserve an offensive and utility when both are available.
3. Use weight 10 for each permanent family and 5 for each applicable consumable. No reroll, replacement or rarity rules.
4. Show one/two offers when only one/two are eligible. Zero candidates grants 500 score automatically; never insert salvage to compete with a useful card.
5. Generate P1 then P2 offers once, before either confirmation; the players may receive the same upgrade, but each player's cards are unique. Navigation, drawing and confirmation order consume no extra offer RNG.
6. Confirm using selection ID, player ID and upgrade ID. Reject stale, duplicate and ineligible confirmations. Recompute eligibility for each queued level after prior choices apply.

Minimum event interfaces: XP collection `(amount, collector_id)`, progression snapshot `(level, xp, next_threshold, pending_count)`, selection request `(selection_id, per_player_offers)` and choice request `(selection_id, player_id, upgrade_id)`, with completion/cancellation routed back to main. Preserve existing parameterless player_died and powerup_collected; the latter announces a confirmed applied choice.

## Foundation ranks

| ID | Category | Ranks and values |
| --- | --- | --- |
| speed | Utility | Four increments of 15 native px/s; 180 to 240 maximum |
| damage | Utility | Five increments of 25% of authored direct base damage; multiplier `1 + 0.25 * rank` |
| fire_rate | Utility | Five decrements of 0.016 seconds; 0.20 to 0.12 seconds |
| orb_magnet | Utility | Base radius 24 px, four increments of 24 px; maximum 120 |
| beam_capacity | Utility | Three capacity bonuses +25 / +50 / +75; personal limit 125 / 150 / 175, preserving existing absolute charge |
| beam_recharge | Utility | Three cell-yield bonuses +25% / +50% / +75%; multiplier 1.25 / 1.50 / 1.75 applied once to each shared base plasma event |
| side_shot | Offensive | Four authored base damages 0.4 / 0.6 / 0.8 / 1.0; first pair at rank 1, outer pair at rank 4 with multiplier 0.6 |
| energy | Repeatable reward | Repair by two energy, immediately clamped to 12; eligible only below maximum |
| shield | Repeatable reward | Add one charge, maximum three; eligible only below maximum; preserve existing charge consumption |
| score | Fallback reward | 500 points, automatically only when no eligible offer remains |

The maintainer approved larger reserves and more efficient cells on 2026-10-20. Both new families consume one personal utility slot and reset with the run. Capacity/recovery selection grants no immediate charge. Shared plasma events retain authored base amounts, then each living player applies their own recovery multiplier and clamps to their current capacity. Full-reserve overdrive uses the upgraded capacity; activation threshold, drain, damage and overdrive duration remain unchanged. Charge values are prototype tuning for subsequent economy/build measurement.

Update current speed_max 225 and shoot_delay_min 0.13 to the new 240 / 0.12 limits only at atomic activation. Damage replaces the old flat gun bonus; do not apply both. Primary/side base caps apply before the common multiplier. Primary at rank 5 is 2.25, not the old 2.50: preserve enemy health and revise obsolete assertions intentionally. Plasma keeps `3 + 0.25 * rank` before overdrive, without the new gun multiplier.

Autonomous direct damage receives the common DAMAGE multiplier once. FIRE_RATE scales missile/drone intervals by `current_manual_delay / 0.20` (minimum factor 0.6); for satellites it scales contact cooldown, not orbit speed. Never scale secondary-effect cooldowns or reapply DAMAGE to an already modified secondary amount.

Keep F1-F8 and existing action names. Player upgrade cheats use the same eligibility rules and report full/capped slots. F9 may fill a deterministic valid maximum test build: side shots, piercing, critical hits, missiles; speed, damage, fire rate; full energy, shield and plasma. It must not silently create an impossible four-utility build. Block stat cheats while choice offers are outstanding.

## XP rewards and collection

| Source | XP chance | XP value |
| --- | ---: | ---: |
| Formation drone, hunter, fighter | 45% | 1 |
| Interceptor | 75% | 4 |
| Standalone turret, carrier hull | 100% | 6 |
| Mounted turret | 60% | 2 |
| Initial small asteroid | 35% | 1 |
| Initial large asteroid | 100% | 2 |
| Spawned asteroid fragment | 0% | 0 |
| Elite | 100% | `max(6, 3 * ordinary_xp_value)` |
| Dread Ark | 100% | 20 |

Boss reinforcements use ordinary family values; boss cannons have no separate XP reward. Escapes, debug cleanup and director retirement give no XP. Mark fragments in their spawn context rather than changing the shared small-asteroid resource. Keep their existing plasma rules.

XP and plasma become independent reward rolls, in fixed XP-then-plasma order on the existing drop stream. Preserve authored plasma chances/quantities, including elite and boss guarantees. Update both Enemy and Dread Ark reward overrides; no old direct power-up may spawn.

Orbs fall at 60 native px/s and home at 260 px/s after entering a living player's attraction radius. Choose nearest player, tie P1, then retain that target until collection or invalidation. A dead target permits reacquisition. Collection radius is 8 px. Values are positive integers; collection credits shared XP exactly once.

Use a world-owned XP orb pool patterned after ProjectilePool's deferred release. Cap active plus reserved entries at 128; merge excess value into the oldest active/reserved orb deterministically instead of losing XP at saturation. Clear value, target, collection latch, reservation, animation and processing state on reuse. Outside-screen orbs recycle normally; an exit callback cannot recycle an already parked orb. Own collection audio outside recycled nodes.

Targets are median first choice 20-25 simulation seconds and subsequent early choices 35-50 seconds apart. These are measured goals, not guarantees for every seed or player. Measure emitted, collected and lost XP separately. Calibrate rewards and collection only; do not compensate by changing encounter density, budgets, health or scheduling. If the formula/drop constraints cannot achieve the goals, stop for an explicit economy revision.

## Combat contract and reproducibility

Add a player-hit entry point to enemies and boss surfaces that returns whether positive damage was actually accepted. Set kill ownership before damage resolution; retain existing _hit_something entry points for unrelated collisions. Rejected hits do not trigger effects or rewards. Every pooled shot snapshots owner, authored/direct damage, modifiers, critical state and source sequence; reset all of them and visited targets on reuse.

Assign deterministic spawn/source identities, not instance IDs, for target sorting. Derive combat RNG per player from the run seed, independent of encounter/drop/offer streams. Critical projectiles roll at emission and retain that result; satellite contacts roll once per accepted direct contact.

Perforation, ricochet, explosion and chain effects cannot multiply damage through the boss's overlapping parts. Treat the whole boss as one damage group within a root projectile/contact and its children. A root hitting a cannon cannot also damage the core through splash/piercing/arcs. An effect originating elsewhere may hit one geometrically visible vulnerable boss surface. New root hits can damage the boss normally. Ordinary distinct enemies retain independent damage groups.

Only a direct projectile's first accepted impact may attempt secondary procs. Snapshot position and values before deferring anything; never keep a reference to a projectile that may be recycled. Spawn/add/reparent collision objects outside physics callbacks. Check line of sight for secondary target acquisition. No secondary damage can create a critical, perforation or another proc. Accepted secondary kills retain the originating player's credit and award normal score/XP/plasma once; rejecting recursive effects must not disable kill rewards.

## New offensive families

All eight have three ranks, weight 10 and no rarity/prerequisite beyond slot eligibility. Numbers below are authored bases before common DAMAGE/FIRE_RATE adjustments.

| ID | Ranks 1 / 2 / 3 | Fixed limits |
| --- | --- | --- |
| piercing | 1 / 2 / 3 extra targets | Damage x0.8 after each accepted target; once per target/group; armor stops the shot |
| critical_hits | 10 / 20 / 30% chance | Direct damage x2; secondary damage uses pre-critical base |
| micro_missiles | Damage 0.9 / 1.1 / 1.3; intervals 1.10 / 0.95 / 0.80 s | One per emission, 3 active, range 220 px, speed 240 px/s, turn 240 deg/s, life 1.8 s |
| escort_drone | Damage 0.6 / 0.75 / 0.9; intervals 0.65 / 0.55 / 0.45 s | One drone, range 180 px; straight bolt speed 360 px/s, life 1 s, 6 active bolts |
| orbiting_satellites | Count 1 / 2 / 3; damage 1 / 1.25 / 1.5 | Orbit radius 32 px, period 2.5 s, contact radius 4 px; shared per-owner/group contact cooldown 0.50 s |
| impact_explosions | Radius 20 / 26 / 32 px; damage x0.35 / x0.45 / x0.55 | At most 4 other targets; per-owner cooldown 0.30 s; exclude initial target/group |
| energy_chains | 1 / 2 / 3 other targets; jump range 72 / 88 / 104 px | Each target receives x0.45 direct pre-critical base; per-owner cooldown 0.50 s; no repeats |
| ricochet | One shard reaches 1 / 2 / 3 other targets | Speed 300 px/s, range 88 px, initial damage x0.55 then x0.8 per rebound; life 1.2 s; 4 active shards; per-owner cooldown 0.40 s |

| Modifier | Main/side cannons | Drone bolts | Missiles | Satellite contacts | Plasma/reflected enemy shots |
| --- | --- | --- | --- | --- | --- |
| Piercing, ricochet | Yes | Yes | No | No | Existing behavior only |
| Crits, explosion, chain | Yes | Yes | Yes | Yes | No new modifier |

Ricochet emits a separate secondary shard; it does not redirect the original projectile. A missile has no intrinsic splash; explosion requires that family. Missiles can reacquire once after target loss, otherwise fly straight to expiry. Weapons with no target retain one ready emission, never an accumulated burst. Saturated caps skip emission without backlog.

All proc cooldowns are per owner across all compatible weapons; denied opportunities are discarded. Multiple different procs may accompany one eligible hit within the common boss-group rule. Pause freezes cooldowns. At owner DYING, stop new emissions/procs and remove drone/satellites; already flying shots complete their bounded lives. Game over/world removal cancels queued requests and clears owned objects.

## Art and opening presentation

Use native 640x400 layout and Lost Warden 64; historical x4 exports or 24-color rules are not current. Keep red/blue ownership, readable silhouettes, pivots, collision agreement and integer pixel placement. Deliver each source with its runtime export and explicit frame/tag mapping.

Foundation art inventory: refreshed primary/side lasers, preserved signature plasma normal/overdrive presentation, ordinary/high-value XP silhouettes with visible gold halos, a dedicated plasma-cell sprite, sixteen upgrade/reward icons, seven-slot strips and reusable card focus/ready states. The HUD uses the exported bar for level progress without a numeric XP counter. New effect art ships inside each matching combat step: piercing treatment, critical impact, missile/thrust/impact, drone/muzzle/bolt, satellites/contact, explosion, energy segments/anchors and ricochet shard/impact.

**Latest maintainer menu-art revision, 2026-10-20:** replace the preceding 32px equipment symbols with **64x64 effect compositions**, authored through the Aseprite MCP using the actual Nomad and projectile sprites. Show the effect in context: long engine exhaust for speed, a stronger primary pulse for damage, a short pulse train for cadence, collectible attraction paths, paired forward wing shots, hull repair, the native reflector and salvage collection. Provide red/blue ownership variants using the real ship/shot assets, with exact Lost Warden 64 colors. Display at native 64px in solo and co-op; keep card text clear. Existing 16px HUD/build miniatures and gameplay pickup footprints remain separate from this menu artwork.

The active player_shot/player_side_shot/beam atlases already have editable masters. animation_rework sheets are separate libraries, not drop-in replacements: map their dimensions/tags deliberately if reused. PlasmaCell currently depends on power_up.png cell 7; migrate it to its dedicated sprite before removing that atlas dependency.

Choice canvas runs while paused, below the inspector and navigation fade. At the safe deferred opening, pause combat immediately and clear held gameplay inputs. Animate an amber/ivory pulse (maximum alpha 0.18, 180 ms), dim to alpha 0.65 over 140 ms, and reveal cards from scale 0.96 to 1 over 180 ms with 40 ms stagger. Cards are interactive after 300 ms and a fresh release/press. No gameplay time_scale changes.

Use one opening per contiguous queued-level batch, shared by both players. Later levels crossfade cards over 120 ms without replaying the full pulse/jingle. Close over 150 ms; release only the selection pause reason. Menu/debug overlays preserve offers/confirmations and never replay the opening. Options can reassign controllers; refresh mappings on return. Keyboard/pad cursors are independent, not one global GUI focus. Mouse actions belong to the clicked player panel.

640x400 layout: shared title at x16/y12/w608/h20 and XP row y36/h12; co-op player panels x16 and x326, y60, w298/h328. Each co-op panel shows player identity, four offensive/three utility cells, three 274x66 cards at y130/204/278, then status/controls near y354. **Explicit visual revision, approved 2026-10-20:** Arsenal déployé replaces the former narrow centered solo panel with a wider solo panel and three horizontal cards. Final solo pixel coordinates and text wrapping are measured at step 3 against native screenshots; co-op retains personal stacked choices. Cards carry icon, name, current-to-next rank and two short numeric effect lines. Keep the fixed core centered when width expands. HUD shows seven icon/rank cells per player and the shared level below SURVIVAL in the right rail. **Maintainer feedback, 2026-10-20:** retain the shared level and its progress bar, removing only the numeric XP counter; preserve progression and the selection screen's XP information. XP pickups use a pulsing additive halo, larger for high-value orbs, with a radial ivory/gold/transparent amber gradient to separate them from scenery.

## Selection audio

Plan a short energetic level-up sting (target 0.5-0.8 s), a compatible restrained synthwave/space selection loop (target 20-30 s before musical boundary editing), navigation/confirmation cues and a short return accent. Route musical assets through Music and UI cues through Sounds; honor their existing mute settings independently.

The maintainer supplies the music and sound effects and approves the result by listening. No Suno generation or prompt preparation is required for these selection assets. Request a level-up sting, selection loop, navigation cue, confirmation cue and return accent, preferably with source/master files and any intended loop points. The agent handles technical import, loop-boundary edits, level matching, Music/Sounds routing and Godot integration; retain the supplied masters and prepare runtime Ogg/WAV exports as needed. No selection files have been supplied yet, so the current visual preview is silent. Prototype selection music is optional and must never block review or choices. Do not repurpose title/game-over music or claim listening acceptance from a waveform/test alone.

Keep audio local to the selection component; do not implement the whole MusicDirector workstream. Pause the same gameplay music player and resume its saved playback position, without stop/play-from-zero. Selection music continues under paused gameplay. A null/muted/blocked stream must never delay interaction. One sting/loop session per batch; no restart for the second player or the next queued level. Do not reuse main._fade_to: it alters Master volume and enables all combat audio during pause. Cancel local tweens/audio callbacks on exit/restart and preserve real screen-navigation ownership.

The foundation may be tested silently with null streams; existing UI cues may support later integration checks if useful. Final audio acceptance requires maintainer-provided assets and a listening review, or an explicit decision to defer that audio item; it must not be silently marked delivered. Missing audio does not block a visual prototype or its interaction.

## Verification and handoff

- Run focused SceneTree suites in the existing addon-free isolated runtime with separate APPDATA. Check actual collision callbacks, deterministic traces, 0/1/2 eligible players, death plus XP in one tick, queued levels, no legacy drops, stale confirmations, pause overlays, restart and legacy saves.
- Keep Alpha 9, elites, beam impact/fire/shield, boss parts/patterns and screen-transition coverage meaningful while replacing obsolete drop/rank assertions. Known baseline limits: historical enemy-feedback failures and inspector shutdown-resource warning; never claim all repository tests pass from the selected baseline.
- Record economy metrics for seeds 0-99 under the same scripted destruction/collection fixture in both modes, then confirm with solo playtests. Separate simulation assumptions from real player behavior. Log first selection, next four intervals and XP produced/collected/lost. No density/health changes.
- Compare precision (side/piercing/crits/missiles), propagation (side/explosion/chain/ricochet), autonomous (missiles/drone/satellites/crits), and proximity (satellites/explosion/chain/drone) builds on identical seeds and encounter data. Each must show a useful strength and observable tradeoff; no build should dominate every measured situation.
- Enumerate the 126 possible four-offensive family sets for compatibility/cap fixtures; sample all four valid three-utility sets. Measure worst-case native solo/co-op load, active/parked counts and frame-time percentiles on the same machine. Require bounded objects/requests and no upward drift through repeated restart/death cycles. Human co-op balance acceptance stays in Phase 6.
- Inspect actual native/wide screenshots and short effect sequences at each art delivery. Verify source/export palette, geometry, ownership, HUD/card readability and plasma identity. Do not infer visual quality or listening acceptance from code.
- Finish each requested step before starting another. Update roadmap/validation evidence only for work actually delivered. Preserve existing local changes; no automatic commit, merge, publication or permanent progression.
