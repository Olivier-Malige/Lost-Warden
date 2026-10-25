# Phase 3 delivery contract

Planning checkpoint: 2026-10-19; preview approved and implementation requested 2026-10-20. Steps 1-4 and 6-12, including the signature-beam piercing revision, are implemented. The maintainer moved chains ahead of missiles and explicitly deferred effect balancing on 2026-10-21, then approved the missile checkpoint. Step 5 has automated measurements and one solo run; remaining human observations and numerical acceptance stay deferred. Steps 13-14 remain pending; explosions now coexist with direct weapons and chains under shared root exclusions. Work through escort drones is published as `f20c148`; the satellite and impact-explosion checkpoints are verified locally for playtest. The concise gameplay roadmap controls delivery order; this contract specifies Phase 3 only. No XP numerical target is revised by the instruction to proceed.

The maintainer approved the silent interactive visual preview with **Arsenal déployé** selected. This preview does not complete a numbered delivery step. The maintainer will provide all music and sound effects; no selection audio files have been supplied yet. Step 1 production references are [art_audio_inventory.md](art_audio_inventory.md) and [selection_audio_brief.md](selection_audio_brief.md).

## Confirmed product decisions

- Borrow the XP, paused choices, growing power and build synergies of Vampire Survivors / Megabonk while retaining the existing shmup controls.
- Each living player has three offensive family slots and three utility family slots (maintainer-approved reduction, 2026-10-22). Acquiring a new family consumes one slot; increasing its rank consumes none. No replacement during a run.
- Utilities are speed, damage, fire rate, XP attraction, plasma reserve, plasma recovery, beam piercing, reflector sphere, reactive armor and retaliation pulse. Offensives are side shots and the additional families below, including guard blades. Repair and fallback score consume no slots. The 2026-10-21 playtest revision retires cannon piercing from offers and assigns the requested nearest-target cannon arc to the `energy_chains` family.
- XP is shared in co-op, choices and equipment are personal. A run ends only after all players die. Human co-op balance acceptance remains deferred until after the power-up and balance rework; verify technical co-op behavior throughout Phase 3.
- Nomad starts with its current primary cannon and its manual secondary signature plasma beam, outside the three offensive slots. Preserve zero initial charge, base capacity 100, activation at 10, drain 20/second and full-reserve overdrive. The maintainer's charge upgrades below can expand personal capacity to 175 and cell recovery to x1.75. No beam unlock card, automatic beam or free permanent beam.
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
| beam_piercing | Utility | 1 / 2 / 3 extra targets; initial damage +20% / +30% / +40%, initial width +25% / +37.5% / +50%; subsequent damage and width x0.8 per crossed target; armor blocks |
| side_shot | Offensive | Four authored base damages 0.4 / 0.6 / 0.8 / 1.0; first pair at rank 1, outer pair at rank 4 with multiplier 0.6 |
| energy | Repeatable reward | Repair by two energy, immediately clamped to 12; eligible only below maximum |
| shield | Utility | Three ranks: 3/5/7 reflector charges, full recharge in 8/6/4 s after depletion; radius 20; body cooldown 0.5 s |
| reactive_armor | Utility | +25/50/75% ordinary injury grace; slowdown/flash remain one second; continuous hazards keep their cadence |
| retaliation_pulse | Utility | Damage 2/3/4, radius 32/40/48, four-second owner cooldown; 120ms expansion/160ms activity/320ms visual lifetime; no criticals/recursive modifiers |
| score | Fallback reward | 500 points, automatically only when no eligible offer remains |

The maintainer approved larger reserves and more efficient cells on 2026-10-20. Both new families consume one personal utility slot and reset with the run. Capacity/recovery selection grants no immediate charge. Shared plasma events retain authored base amounts, then each living player applies their own recovery multiplier and clamps to their current capacity. Full-reserve overdrive uses the upgraded capacity; activation threshold, drain, damage and overdrive duration remain unchanged. Charge values are prototype tuning for subsequent economy/build measurement.

Update current speed_max 225 and shoot_delay_min 0.13 to the new 240 / 0.12 limits only at atomic activation. Damage replaces the old flat gun bonus; do not apply both. Primary/side base caps apply before the common multiplier. Primary at rank 5 is 2.25, not the old 2.50: preserve enemy health and revise obsolete assertions intentionally. Plasma keeps `3 + 0.25 * rank` before overdrive, without the new gun multiplier.

Autonomous direct damage receives the common DAMAGE multiplier once. FIRE_RATE scales missile/drone intervals by `current_manual_delay / 0.20` (minimum factor 0.6); for satellites it scales contact cooldown, not orbit speed. Never scale secondary-effect cooldowns or reapply DAMAGE to an already modified secondary amount.

Keep F1-F8 and existing action names. Player upgrade cheats use the same eligibility rules and report full/capped slots. F9 may fill a deterministic valid maximum test build from completed families; never force an unavailable family or an impossible four-utility build. Block stat cheats while choice offers are outstanding. Debug L completes the current XP threshold through the normal queued-choice flow and is blocked outside an eligible active run or while selection is outstanding.

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

These families have three ranks, weight 10 and no rarity/prerequisite beyond slot eligibility. Numbers below are authored bases before supported common stat adjustments. Cannon piercing was moved to beam utility after playtest. Critical hits, micro-missiles, escort drones, orbiting satellites, impact explosions, energy chains and guard blades are live; ricochet remains pending. The maintainer explicitly defers effect balancing; these prototype values remain authored and visible in cards.

| ID | Ranks 1 / 2 / 3 | Fixed limits |
| --- | --- | --- |
| critical_hits | 10 / 20 / 30% chance | Direct damage x2; secondary damage uses pre-critical base |
| micro_missiles | 1 / 2 / 3 per volley, small / medium / large sprites; damage 0.9 / 1.1 / 1.3; intervals 1.10 / 0.95 / 0.80 s | 3 active/reserved per owner; partial volleys use remaining capacity; range 220 px, speed 240 px/s, turn 240 deg/s, life 1.8 s; no electric chains |
| escort_drone | 1 / 1 / 2 companions; damage 0.6 / 0.75 / 0.9 per bolt; intervals 0.65 / 0.55 / 0.45 s per companion | Range 180 px in a screen-up 90-degree cone; straight bolt speed 360 px/s, life 1 s; 6 active/reserved bolts shared per owner; no electric chains |
| orbiting_satellites | Count 1 / 2 / 3; damage 1 / 1.25 / 1.5 | Orbit radius 32 px, period 1.25 s, independent spin period 0.625 s, contact radius 4 px; shared per-owner/group contact cooldown 0.50 s |
| impact_explosions | Radius 24 / 30 / 36 px; damage x0.70 / x0.90 / x1.10 | All overlapping additional targets; 160ms active wave; per-owner cooldown 0.30 s; exclude initial target/group |
| energy_chains | 1 / 2 / 3 other targets; jump range 72 / 88 / 104 px | Each target receives x0.45 direct pre-critical base; per-owner cooldown 0.50 s; no repeats |
| guard_blades | Damage 2 / 3 / 4; start intervals 3 / 2 / 1.5 s | Inner gap 16, outer reach 60 / 72 / 84; two forward 40-degree sectors, left center -160 to -90 and right -20 to -90 degrees in 160ms, then 120ms bright active overlap; 280ms active/400ms visual; 0.6s anticipation before each salvo (inside recurring intervals); one hit per hull/boss group and hostile-shot clearing; DAMAGE once, no FIRE_RATE/crit/procs |
| ricochet | One shard reaches 1 / 2 / 3 other targets | Speed 300 px/s, range 88 px, initial damage x0.55 then x0.8 per rebound; life 1.2 s; 4 active shards; per-owner cooldown 0.40 s |

| Modifier | Main cannon | Side cannons | Drone bolts | Missiles | Satellite contacts | Plasma/reflected enemy shots |
| --- | --- | --- | --- | --- | --- | --- |
| Ricochet | Yes | Yes | Yes | No | No | No new modifier |
| Beam piercing | No | No | No | No | No | Manual plasma only; reflected shots excluded |
| Crits, explosion | Yes | Yes | Yes | Yes | Yes | No new modifier |
| Energy chains | Yes | No | No | No | No | No new modifier |

Guard blades are an offensive family whose independent salvos use the SECONDARY hit kind. They receive no modifier in the compatibility table: no criticals, electric chains, explosions, piercing or ricochet. Their shared salvo root retains kill ownership and one accepted surface per boss. Explicit armor blocks damage/shot clearing; reflected or allied shots and continuous beams survive. See the approved [guard-blade contract and validation](../2026_10_24_guard_blades/validation.md).

Maintainer forward-targeting revision: missile acquisition, retained-target validation and the single reacquisition use a 90-degree screen-up cone (45 degrees either side of Nomad's forward axis). Closer side/rear enemies are excluded. A target leaving that cone is lost, so a passed target cannot cause a U-turn. Other weapons' targeting remains unrestricted unless their own contract says otherwise.

Ricochet emits a separate secondary shard; it does not redirect the original projectile. A missile has no intrinsic splash; explosion requires that family. Following the maintainer's 2026-10-21 feedback, smaller native missile art grows by rank alongside 1/2/3-projectile volleys. Hull collisions follow 3x6 / 4x8 / 5x10 px at offsets (0,-1) / (0,-2) / (0,-3); no fractional sprite scaling is used. Missile impacts retain criticals but cannot trigger electric chains or consume their cooldown. Missiles can reacquire once after target loss, otherwise fly straight to expiry. Weapons with no target retain one ready emission, never an accumulated burst. Saturated caps skip emission without backlog; a volley may use fewer entries when only part of its capacity is free.

All proc cooldowns are per owner across all compatible weapons; denied opportunities are discarded. Multiple different procs may accompany one eligible hit within the common boss-group rule. Pause freezes cooldowns. At owner DYING, stop new emissions/procs and remove drone/satellites; already flying shots complete their bounded lives. Game over/world removal cancels queued requests and clears owned objects.

## Art and opening presentation

Use native 640x400 layout and Lost Warden 64; historical x4 exports or 24-color rules are not current. Keep red/blue ownership, readable silhouettes, pivots, collision agreement and integer pixel placement. Deliver each source with its runtime export and explicit frame/tag mapping.

Foundation art inventory: refreshed primary/side lasers, preserved signature plasma normal/overdrive presentation, ordinary/high-value XP silhouettes with visible gold halos, a dedicated plasma-cell sprite, seventeen upgrade/reward icons, seven-slot strips and reusable card focus/ready states. The HUD uses the exported bar for level progress without a numeric XP counter. New effect art ships inside each matching combat step: piercing treatment, critical impact, missile/thrust/impact, drone/muzzle/bolt, satellites/contact, explosion, energy segments/anchors and ricochet shard/impact.

**Latest maintainer menu-art revision, 2026-10-20:** replace the preceding 32px equipment symbols with **64x64 effect compositions**, authored through the Aseprite MCP using the actual Nomad and projectile sprites. Show the effect in context: long engine exhaust for speed, a stronger primary pulse for damage, a short pulse train for cadence, collectible attraction paths, paired forward wing shots, hull repair, the native reflector and salvage collection. Provide red/blue ownership variants using the real ship/shot assets, with exact Lost Warden 64 colors. Display at native 64px in solo and co-op; keep card text clear. Existing 16px HUD/build miniatures and gameplay pickup footprints remain separate from this menu artwork.

The active player_shot/player_side_shot/beam atlases already have editable masters. animation_rework sheets are separate libraries, not drop-in replacements: map their dimensions/tags deliberately if reused. PlasmaCell currently depends on power_up.png cell 7; migrate it to its dedicated sprite before removing that atlas dependency.

Choice canvas runs while paused, below the inspector and navigation fade. At the safe deferred opening, pause combat immediately and clear held gameplay inputs. Animate an amber/ivory pulse (maximum alpha 0.18, 180 ms), dim to alpha 0.65 over 140 ms, and reveal cards from scale 0.96 to 1 over 180 ms with 40 ms stagger. Cards are interactive after 300 ms and a fresh release/press. No gameplay time_scale changes.

Use one opening per contiguous queued-level batch, shared by both players. Later levels crossfade cards over 120 ms without replaying the full pulse/jingle. Close over 150 ms; release only the selection pause reason. Menu/debug overlays preserve offers/confirmations and never replay the opening. Options can reassign controllers; refresh mappings on return. Keyboard/pad cursors are independent, not one global GUI focus. Mouse actions belong to the clicked player panel.

640x400 layout: shared title at x16/y12/w608/h20 and XP row y36/h12; co-op player panels x16 and x326, y60, w298/h328. Each co-op panel shows player identity, three offensive/three utility cells, three 274x66 cards at y130/204/278, then status/controls near y354. **Explicit visual revision, approved 2026-10-20:** Arsenal déployé replaces the former narrow centered solo panel with a wider solo panel and three horizontal cards. Final solo pixel coordinates and text wrapping are measured at step 3 against native screenshots; co-op retains personal stacked choices. Cards carry icon, name, current-to-next rank and two short numeric effect lines. Keep the fixed core centered when width expands. HUD shows six icon/rank cells per player and the shared level below SURVIVAL in the right rail. **Maintainer feedback, 2026-10-20:** retain the shared level and its progress bar, removing only the numeric XP counter; preserve progression and the selection screen's XP information. XP pickups use a pulsing additive halo, larger for high-value orbs, with a radial ivory/gold/transparent amber gradient to separate them from scenery.

## Approved gameplay readability revision — 2026-10-20

The maintainer approved a stronger critical effect and replacing gameplay points/combo displays with a shared elimination count. The count resets each run and increases only once per player-owned enemy destruction, including one for a boss hull; asteroid hazards, optional boss parts, escapes, cleanup and score-only salvage do not increase it. Route updates through Events, without HUD-to-player coupling. Remove floating score/combo popups during gameplay; retain internal scoring, record compatibility and score on the existing results screens. Keep survival time, level and the nonnumeric level-progress bar. Use a 24px, six-frame, 300 ms owner-colored critical impact and a brief longer flash on the struck enemy/cannon. No floating damage numbers or new audio are enabled by this revision.

## Selection audio

Plan a short energetic level-up sting (target 0.5-0.8 s), a compatible restrained synthwave/space selection loop (target 20-30 s before musical boundary editing), navigation/confirmation cues and a short return accent. Route musical assets through Music and UI cues through Sounds; honor their existing mute settings independently.

The maintainer supplies the music and sound effects and approves the result by listening. No Suno generation or prompt preparation is required for these selection assets. Request a level-up sting, selection loop, navigation cue, confirmation cue and return accent, preferably with source/master files and any intended loop points. The agent handles technical import, loop-boundary edits, level matching, Music/Sounds routing and Godot integration; retain the supplied masters and prepare runtime Ogg/WAV exports as needed. No selection files have been supplied yet, so the current visual preview is silent. Prototype selection music is optional and must never block review or choices. Do not repurpose title/game-over music or claim listening acceptance from a waveform/test alone.

Keep audio local to the selection component; do not implement the whole MusicDirector workstream. Pause the same gameplay music player and resume its saved playback position, without stop/play-from-zero. Selection music continues under paused gameplay. A null/muted/blocked stream must never delay interaction. One sting/loop session per batch; no restart for the second player or the next queued level. Do not reuse main._fade_to: it alters Master volume and enables all combat audio during pause. Cancel local tweens/audio callbacks on exit/restart and preserve real screen-navigation ownership.

The foundation may be tested silently with null streams; existing UI cues may support later integration checks if useful. Final audio acceptance requires maintainer-provided assets and a listening review, or an explicit decision to defer that audio item; it must not be silently marked delivered. Missing audio does not block a visual prototype or its interaction.

## Verification and handoff

- Run focused SceneTree suites in the existing addon-free isolated runtime with separate APPDATA. Check actual collision callbacks, deterministic traces, 0/1/2 eligible players, death plus XP in one tick, queued levels, no legacy drops, stale confirmations, pause overlays, restart and legacy saves.
- Keep Alpha 9, elites, beam impact/fire/shield, boss parts/patterns and screen-transition coverage meaningful while replacing obsolete drop/rank assertions. Known baseline limits: historical enemy-feedback failures and inspector shutdown-resource warning; never claim all repository tests pass from the selected baseline.
- Record economy metrics for seeds 0-99 under the same scripted destruction/collection fixture in both modes, then confirm with solo playtests. Separate simulation assumptions from real player behavior. Log first selection, next four intervals and XP produced/collected/lost. No density/health changes.
- Compare precision (side/crits/missiles plus beam utility), propagation (side/explosion/chain/ricochet), autonomous (missiles/drone/satellites/crits), and proximity (satellites/explosion/chain/drone) builds on identical seeds and encounter data. Each must show a useful strength and observable tradeoff; no build should dominate every measured situation.
- Enumerate the 70 possible four-offensive family sets from eight total families for compatibility/cap fixtures; sample all 35 three-utility sets from seven families. Measure worst-case native solo/co-op load, active/parked counts and frame-time percentiles on the same machine. Require bounded objects/requests and no upward drift through repeated restart/death cycles. Human co-op balance acceptance stays in Phase 6.
- Inspect actual native/wide screenshots and short effect sequences at each art delivery. Verify source/export palette, geometry, ownership, HUD/card readability and plasma identity. Do not infer visual quality or listening acceptance from code.
- Finish each requested step before starting another. Update roadmap/validation evidence only for work actually delivered. Preserve existing local changes; no automatic commit, merge, publication or permanent progression.

The maintainer revised step 9 on 2026-10-21: escort hulls bank left/right with Nomad movement, their reduced twin reactors copy its current smoothed forward/idle/braking response and team gradients, and the final rank adds the opposite-shoulder companion. This replaces the original one-drone-at-every-rank clause without increasing the common six-bolt owner cap. Cannon piercing remains dormant; drone bolts preserve its compatibility in fixtures. The later maintainer revision below excludes electric chains from drone bolts.

Forward-fire revision, 2026-10-21: each escort acquires only within its authored 90-degree screen-up cone (inclusive +/-45 degrees) from the actual muzzle. Visual banking does not rotate this cone. Rear/lateral-only targets preserve ready state and do not trigger a muzzle flash. Once emitted, the bolt retains its straight vector.

Escort glide prototype, approved 2026-10-21: rendered hulls, emitters and twin reactors share a trailing displacement from actual owner movement, bounded to 8 px with exponential settling (responses 9 / 11 per second by shoulder). A deterministic independent hover adds at most 0.65px horizontally and 1.5px vertically. Rendering offsets round to native pixels before arena clamps; root shoulder anchors stay fixed. Pause freezes the effect and each fresh support starts without inherited lag. Forward targeting still originates at the displayed muzzle.

Escort chain exclusion, approved 2026-10-21: drone bolts retain direct criticals but cannot trigger electric chains, emit arc visuals or consume the cannon chain cooldown. Strip the modifier at emission and guard the DRONE source kind at proc resolution, including unfiltered packets. Main/side cannon chains remain available immediately after drone impacts.

Step 10 implementation checkpoint, 2026-10-21 (chain compatibility superseded on 2026-10-22): satellite contact initially remained compatible with direct criticals and the already completed chain family. Cooldowns belong to each owner/logical target group, expire without retained actors and are not bypassed by re-entry or multiple orbiters. Pause and actual physics-callback death cleanup are verified. The maintainer's preceding drone/missile chain exclusions remain intact.

### Step 11 coexistence checkpoint — 2026-10-21

Explosion requests snapshot the impact center, pre-critical amount, owner, rank, origin exclusions and visited groups before deferral. Chains retain their existing resolution order, followed by explosions; both consult the shared root history, so a target group already reached by one cannot receive the same root again. Each splash ray starts at the original impact and requires visibility; it does not propagate from a previous victim. Its four-target budget counts accepted additional groups only. Even isolated accepted impacts show one finite explosion and consume the 0.30-second personal cooldown. No backlog is retained. Visuals are fresh non-colliding instances with a 320ms lifetime and an eight-instance global cap; no VFX pool or projectile reference is retained.

### Maintainer playtest revision — 2026-10-22

Explosion radius is now 32/40/48px (+25%/+50% relative to rank one), with 35/45/55% modified pre-critical damage unchanged. Selection text uses percentage radius bonuses rather than pixels. Acquire actual collision-shape overlaps with a circular physics query, bounded to 512 surfaces (above the director's active budget), then require line of sight and sort by nearest visible surface distance and spawn identity. Preserve the four accepted additional groups, origin exclusions, boss grouping and owner cooldown. Fresh 96px native animation cells match the expanded footprint.

The shared source/modifier policy lives in `PlayerHitSnapshot.SOURCE_MODIFIERS` and `allows_modifier`. Only GUN (main/side) can trigger electric chains. Satellites lose their earlier chain compatibility; missile/drone exclusions are retained. Criticals/explosions remain explicitly enabled for gun/missile/drone/satellite direct sources. Legacy cannon/drone piercing and planned ricochet compatibility stay separate. Snapshot construction strips incompatible combat modifiers and rejects critical flags on disallowed sources; service queue guards consult the same policy. New sources and effect identifiers default to no authorization, so future procs must explicitly opt in. Remove per-emitter erase lists rather than extending a denylist with every new weapon. Secondary hits cannot trigger any modifier.

### Final concentrated-blast and main-cannon revision — 2026-10-22

The maintainer explicitly excludes side shots from lightning and requests smaller, harder-hitting explosions. This supersedes the preceding source/radius tuning: GUN now means the main cannon only; append SIDE_GUN without changing existing enum ordinals. Every inner/outer side emission explicitly uses SIDE_GUN. Its policy retains criticals, explosions and legacy/planned piercing/ricochet, but forbids chains. Only GUN can start or consume the chain cooldown. New cannon emission call sites must supply a source kind explicitly.

Explosion radius becomes 24/30/36px (25% smaller than 32/40/48), with damage 70/90/110% of modified pre-critical direct damage (twice 35/45/55%). Rank radius bonuses remain +25%/+50% relative to rank one. Real hull overlap, four other groups, visibility/armor, boss exclusions, non-recursion and 0.30-second owner cooldown are unchanged. Aseprite art is rebaked to the smaller footprint on the same 96px grid.

### Approved expanding-wave correction — 2026-10-22

The maintainer approved the replacement plan after the compact instant blast still felt ineffective. This supersedes earlier four-target and shared-secondary-history clauses for step 11. Preserve radii 24/30/36, factors 0.70/0.90/1.10 and 0.30s cooldown. A service-owned physics wave expands from 25% to full radius over 0.12s, remains damaging through 0.16s and leaves only visual fragments through 0.32s. It repeatedly queries real hull overlaps, damages each additional group once and has no four-target cap (`target_limit = 0`). Ordinary hulls/asteroids cannot occlude the blast; explicit armor still can.

Ordinary groups now have independent energy-chain and explosion histories, so the two effects stack once each in either order. Directly hit groups remain excluded and boss history is global across channels. Secondary hits remain non-critical/non-recursive. `resolve_hit` gains an optional `channel` defaulting to `root`; existing callers retain their behavior. A copied hit is retained only through the active interval; the service also owns the visual clock and cleanup. Visual limits cannot suppress damage. See [wave evidence](validation/impact_explosion_wave.md) for the 263 native checks, real moving formations and current art/diagnostics.

### Approved steel satellite revision — 2026-10-22

The maintainer accepted the explosion checkpoint for now and approved revisiting contact satellites before ricochets. All ranks orbit in 1.25 seconds and spin independently in 0.625 seconds, clockwise with deterministic per-orbiter orientation offsets. Both phases survive rank changes and freeze with the physics clock during pause. `UpgradeDefinition.spin_period` is authored, included in offers and validated as positive and finite for satellites only. Counts, damage, cooldown, radius-four core contacts, ownership and source compatibility remain unchanged. Four tapered steel spikes are decorative. The maintainer rejected the first flat cross-like art during implementation; the delivered replacement uses a beveled core, thin spikes and separate editable metal, insert and contact layers. This supersedes the earlier 2.5-second orbit and outward-only presentation.

### Satellite sprite rotation simplification — 2026-10-22

The maintainer requested one hull orientation per player with scripted rotation. Use one red and one blue 16px sprite orientation plus the existing reflection/contact frames, rotating only Sprite2D continuously. This replaces the baked eight-way art mapping without changing orbital/spin periods, combat or collision geometry. The Aseprite source and runtime export now use two team rows.

### Maintainer-approved defensive utility pack — 2026-10-22

The approved [defensive pack](../2026_10_22_defensive_pack/plan.md) supersedes the earlier consumable-shield clauses. The existing `shield` ID is now a three-rank regenerating sphere, joined by reactive armor and retaliation pulse as ordinary utility families. They share the existing three slots; no extra category, permanent progression or ricochet is introduced. Exact delivered behavior and acceptance evidence are in [the defensive validation](../2026_10_22_defensive_pack/validation.md). The live catalog has 19 entries; energy remains the repeatable reward.
