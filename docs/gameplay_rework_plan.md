# Gameplay roadmap

Updated: 2026-10-28.

**Goal:** a continuous survival shmup with varied builds, enemies and formations, increasing pressure over time, solo and local co-op.

**Current defensive contract (2026-10-26):** [distinct defensive roles](../aidd_docs/tasks/2026_10/2026_10_26_defense_role_split/plan.md) supersede earlier sphere contact protection. Reflection handles projectiles only; actual enemy/asteroid contact breaks it without absorbing damage, and beams bypass it. Retaliation independently protects against enemy or asteroid body contact and can trigger on the same collision. Projectiles and beams never trigger it. Updated selection copy, native ship icons and owner-colored reflection/golden explosion effects distinguish the roles. Reflection now restores its original red/blue sphere colors and icons at the maintainer's request. The maintainer rejected the generated mirror/starburst style. Later size feedback reduces rank one's radius to 48px (ranks two/three remain 80/96px) and replaces magnified explosion pixels with a native-size golden animation.

The split is implemented locally. [Validation](../aidd_docs/tasks/2026_10/2026_10_26_defense_role_split/validation.md): 142 targeted reflector checks, 343 native defensive checks, affected combat/offer regressions and native presentation pass. Seventy-two unrelated atlas cells remain pixel-identical and both editable atlas exports match the updated PNGs. The selection suite passes its assertions but retains a documented MP3 shutdown warning. Await maintainer playtest.

**Selection input safety (2026-10-26):** firing no longer confirms upgrade choices. Enter/keypad Enter confirms for the keyboard owner, and Start confirms for the assigned gamepad owner. Held confirmation must be released before accepting the next queued choice. Start still pauses ordinary gameplay. Solo and co-op hints show these controls. See [input and missile follow-up validation](../aidd_docs/tasks/2026_10/2026_10_26_input_and_missile_followups/validation.md).

**Current Reactive Armor contract (2026-10-28):** the maintainer approved replacing extra injury invulnerability with delayed hull repair. A nonfatal hull injury starts one repair: restore one energy point after 8/6/4 seconds without further hull damage. New damage restarts the delay; one completed recovery restores only one point. Reflected or Retaliation-protected hits do not start or reset it. Ordinary one-second injury grace remains. A green personal HUD progress bar/countdown and `REPAIRED +1` feedback explain the effect, with explicit hull-damage and quiet-delay copy on the card. [Implementation and validation](../aidd_docs/tasks/2026_10/2026_10_28_reactive_repair/validation.md): 74 headless and 122 native repair checks pass, plus affected defense, collision, offer and selection regressions. Earlier extra-grace checkpoints below are historical. Await maintainer playtest.

**Next step:** Playtest Guard Blades with the defensive close-range build, retaining three offensive and three utility slots. The maintainer approved this addition before step 13 ricochet shards, which still awaits a separate request. Steps 1-4 and 6-12 are implemented. Missiles, drone bolts and satellites retain criticals and explosions but remain excluded from electric chains; piercing belongs to the manual signature beam. The current playtest checkpoint adds satellites, explosions, defensive utilities and contact/build corrections after the published escort checkpoint. Step 5 still needs two solo observations and qualitative feedback. The maintainer explicitly defers effect balancing; prototype values remain recorded. Dedicated selection audio remains pending. See [Phase 3 evidence](phase_3_validation.md).

## Progress and delivery order

| Phase | Scope | Status |
| --- | --- | --- |
| Preparation, Phase 1 and art | Original identity, display, core combat, controls, plasma and graphics | Complete |
| 2 — Continuous survival | Seeded encounters, elites, first boss, survival UI and records | Complete; solo accepted, co-op playtest deferred |
| 3 — Experience and power-ups | XP, personal builds, original weapon sprites and audiovisual level-up choices | In progress; steps 1-4 and 6-12 implemented; plasma piercing, criticals, chains, micro-missiles, escort drones, orbiting satellites, impact explosions and guard blades playable; human XP acceptance deferred |
| 4 — Enemies and density | Redesign current enemies, add roles, enrich formations, increase pressure over time | Planned; after Phase 3 |
| 5 — Combat effects | Impacts, explosions, collections and upgrade feedback | Planned |
| 6 — Final balance | Complete solo/co-op runs, performance and regression checks | Planned; includes deferred co-op gameplay acceptance after power-up and balance rework |

## Phase 2 — Continuous survival foundation

Closed on 2026-10-19: the maintainer accepts solo gameplay and explicitly defers the co-op gameplay playtest until after the power-up and balance rework. Automated solo/co-op regressions and native presentation checks pass; they do not replace the deferred human co-op acceptance. See the [validation checkpoint](phase_2_validation.md#phase-2-closure--2026-10-19).

Done: continuous seeded encounters, threat budgets, formations, enemy caps, survival timer, solo/co-op duration records, game-over and hiscore screens. Deterministic elites now have approved markings, a small health bar and a three-elite cap. Danger stays internal. F1/F2 adjust danger; N skips a regular encounter in debug mode.

New runs leave three seconds before the first formation, in solo and co-op. Pause freezes this opening respite; subsequent encounters retain their normal timing.

The Dread Ark has two phases, switching at 50% health. Phase one cycles rings, aimed salvos, spirals, aimed salvos and drones; phase two adds a dedicated beam attack. Rings keep a 30-degree opening; spirals alternate rotation with 16 / 20 emissions, and circular missiles travel more slowly than aimed salvos. Core health remains 650 solo / 1,040 co-op; cannons have 90 / 144 HP. Faster seeded repositioning combines acceleration, braking, short rests and height changes; beams lock its position. Its health bar has two segments without numeric health or phase text. Five-minute milestones and eight-second recovery remain in place.

Natural milestones enter `BOSS_APPROACH`: stop new formations, preserve existing enemies, asteroid fragments and enemy shots, then wait for an empty arena and 0.5 seconds of calm. Survival time continues; regular scheduling and the calm window respect pause. F12 retains immediate debug cleanup.

Rings and spirals emit round red energy balls from the central cannon mouth, with a local charge/fire/recovery effect and continuous phase hull animation. Aimed salvos retain elongated missiles. The new editable Aseprite assets use Lost Warden 64 exclusively. Attacks retain their charging animations without projected ring guides or beam-lane indicators.

Two optional destructible cannons have independent health, local shader hit feedback and persistent wrecks. Each destroyed cannon loses its targeted salvos and lateral beam; the core retains circular patterns and its wide central beam. Drone launches contain four solo / six co-op hunters, capped at eight / twelve including reservations; incomplete groups are skipped. Phase changes cancel pending launches and active boss missiles. Defeat chains hull explosions into a large final blast and strong screen shake.

Boss beams deal one energy point on contact and every 0.35 seconds of continued exposure, with independent player cooldowns. Leaving the damage core stops further drain.

Six regular encounter types now mix formation drones with hunters using distinct arrowhead interceptor sprites, dark neutral hulls and red sensors matching the boss palette; elites have amber armor. Their hull and exhausts face their actual velocity. Hunters pursue at 175 px/s, commit to a straight attack 64 pixels before reaching the player, then progressively turn downward after crossing the height locked at commitment. Boss reinforcements share this behavior and appearance.

Unmodified player beams stop at the first impact, damage only that obstacle and extend to the next target when it is destroyed. Phase 3's optional piercing utility extends this behavior; armor still blocks it. Boss armor, core and cannons use their own collision surfaces.

Debug tools: **F11** toggles compact metrics; **F10** opens the [paused full inspector](debug_screen.md); **F12** starts a boss immediately during active gameplay.

No implementation remains in Phase 2. Carry the deferred co-op gameplay acceptance into Phase 6, after the power-up and balance rework.

## Phase 3 — Create varied survival builds

The [detailed plan](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/plan.md) and its [delivery contract](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/contract.md) record the maintainer's direction and prototype values. Steps 1-4, 6-10 and standalone 12 are implemented. Automated XP measurement exists; human calibration acceptance and later offensive families remain pending. Execute only the requested numbered step, then verify and stop for review.

Replace direct drops with pooled XP and paused choices inspired by Vampire Survivors / Megabonk. Share XP in co-op with personal offers and three offensive plus three utility family slots per player. Acquired families stay for the run; rarity remains deferred.

Nomad retains its native manual secondary plasma beam and reserve, outside the offensive slots. Future ship signatures remain planning-only; no ship selection or permanent progression is included.

Prepare dormant models and a complete animated selection screen before activating XP, rewards, foundation ranks and HUD together. Deliver each offensive family in bounded checkpoints with editable sources, runtime sprites and native visual verification. Following the maintainer's playtest, piercing belongs to the manual plasma beam as a utility. The cannon's nearest-target electric arc is now playable: 1/2/3 other targets within 72/88/104 px, 45% pre-critical damage per jump and a 0.5-second personal cooldown. Obstacles block the links; secondary effects cannot recurse. Impact explosions are playable; ricochet shards remain pending. See [chain evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/energy_chains.md).

The three beam-piercing ranks cross 1/2/3 extra targets, add 20/30/40% initial damage and raise normal width from 8 to 10/11/12 px (overdrive 20/22/24 px). Each crossed target reduces subsequent damage and width to 80%. These prototype bonuses apply only with this utility, occupy one utility slot, grant no plasma and preserve manual drain and armor blocking. See [beam verification](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/beam_piercing.md).

Include refreshed player lasers, XP and dedicated plasma-cell sprites, upgrade icons and a strong level-up opening. Plan one musical sting/selection loop session per queued-level batch, with gameplay music resuming at its previous position. Follow the [selection audio scope](sound_design_plan.md#phase-3-selection-moment--brief-verified-2026-10-20) for production/listening; the full MusicDirector workstream remains separate.

First playable feedback (2026-10-20): XP orbs now use visible pulsing gold halos, with larger halos for high-value pickups. Retain the shared level and its progress bar in the HUD, without a numeric XP counter. Halos fade radially from ivory through gold to transparent amber; XP thresholds and selection information are unchanged.

Further approved follow-ups: 64px Nomad effect illustrations and matching 16px team miniatures; two three-rank utility families for plasma capacity (+25 per rank, up to 175) and cell recovery (+25% per rank, up to x1.75). They share the three utility slots, preserve current charge on acquisition, and retain manual beam drain/full-reserve overdrive. XP collection now plays a short dedicated procedural ping on Sounds, with bounded burst playback. These additions are playable prototypes; economy calibration and human audio/balance acceptance remain pending.

Verify that different choices produce different, useful builds before redesigning enemy pressure.

Micro-missiles fire autonomously at nearby visible targets, including during manual cannon or plasma use. Three ranks provide 1/2/3 missiles per volley, increasing native sprite sizes, damage 0.9/1.1/1.3 and intervals 1.10/0.95/0.80 seconds before common DAMAGE/FIRE_RATE adjustments. Each owner has at most three active/reserved missiles, speed 240 px/s, turn limit 240 degrees/s and 1.8-second lifetime. Physical impacts can critically strike but cannot trigger electric chains, piercing or ricochet; no intrinsic splash. Dedicated body/thrust/impact and card art ship together. See [missile evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/micro_missiles.md).

Latest missile targeting revision (2026-10-26): launches retain their 90-degree screen-up cone. After missing or losing a target, missiles choose the nearest visible, unobstructed enemy strictly above their current position within the existing 220px range, including upper targets outside the launch cone. Further losses can retarget again; previously missed logical groups stay excluded, and targetless searches retry at 100ms intervals. Replacement guidance remains in the upper half-plane, without a downward U-turn or renewed lifetime. Cannon chains retain their existing targeting. See [follow-up validation](../aidd_docs/tasks/2026_10/2026_10_26_input_and_missile_followups/validation.md).

### Step 9 escort checkpoint — 2026-10-21

Escort drones fire straight aimed bolts independently of manual cannons/plasma. Ranks provide one / one / two companions (second drone at rank three), damage 0.6 / 0.75 / 0.9 and intervals 0.65 / 0.55 / 0.45 s before the common stat factors. Six active/reserved bolts are shared per owner; range is 180 px within a 90-degree screen-up cone (+/-45 degrees), speed 360 px/s and lifetime one second. Hulls bank with Nomad movement; reduced copies of its twin reactor effect share the current smoothed movement response and team palette. Visual emitters tuck inside the arena at the edges while player movement bounds remain unchanged. Drone impacts cannot trigger electric chains or consume the cannon chain cooldown; direct criticals remain available. Pause freezes support/flight; DYING removes both companions and cancels new owned emissions/procs. See [escort evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/escort_drone.md). Balancing remains deferred.

### Step 10 satellite checkpoint — 2026-10-21

Ranks provide one / two / three contact orbiters at radius 32 px, fixed period 2.5 seconds and contact radius 4 px. Direct damage is 1 / 1.25 / 1.5 before common DAMAGE; FIRE_RATE only scales the 0.50-second owner/group cooldown. All boss parts share one group, while P1/P2 keep independent timers and critical streams. Satellites do not block enemy shots; criticals and impact explosions remain compatible; the final 2026-10-22 revision restricts electric chains to the main cannon only. Dedicated Aseprite orbit/contact art, cards and miniatures ship together. Pause and deferred DYING cleanup are verified through actual physics. See [satellite evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/orbiting_satellites.md). The preceding escort checkpoint is published as `f20c148`; this checkpoint remains local for playtest.

## Phase 4 — Redesign enemies, formations and density

- Revisit every existing enemy family and asteroid hazards; define clear roles and varied movement/attack patterns.
- Add the dive hunter, bomber and sniper. Expand formations with diagonals, pincers, escorts and coordinated mixed groups, keeping dodge openings.
- Increase spawn pressure as survival time passes. Tune density against the completed power-up system, with readable attacks and measured solo/co-op performance.

## Delivery rules

- Implement only the requested step, verify it, then stop for maintainer review.
- Complete the power-up rework before the full enemy/formation redesign and density tuning.
- Keep seeded gameplay reproducible, collision/pooling operations safe, and old saves compatible. A run ends when every player is dead; upgrades reset for each run.
- Permanent progression remains deferred to a separate approved roadmap. Audio follows its own plan.

## Detailed references

- [Technical requirements and history](gameplay_rework_reference.md): retained numerical rules and acceptance criteria. This concise roadmap controls current status and ordering.
- [Phase 2 validation](phase_2_validation.md): implementation evidence and known issues.
- [Sound design plan](sound_design_plan.md): separate audio workstream.

### Step 11 impact explosion checkpoint — 2026-10-21

The first accepted compatible direct impact can create one explosion: radius 24/30/36 px with real collision-shape overlap, 70/90/110% modified pre-critical damage and every additional hull reached by the brief expanding disk. Cannons, missiles, drone bolts and satellite contacts share a 0.30-second owner cooldown unaffected by FIRE_RATE. Secondary damage cannot recurse or critically strike; per-effect histories allow chain/blast stacking on ordinary hulls, while direct-target and boss exclusions remain shared. Dedicated eight-frame Aseprite explosions, cards and miniatures preserve Lost Warden 64 and personal ownership. [Explosion evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/impact_explosions.md) records the initial tuning checks; the [wave correction](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/impact_explosion_wave.md) adds 263 native checks after the approved expanding-wave revision and affected regressions. Cards show +25% / +50% radius over rank one. Broader final balancing and new audio remain deferred. Stop for playtest before step 13.

### Explosion reach and effect compatibility revision — 2026-10-22

The maintainer requested more effective splash and percentage-based descriptions. Explosion radii increase from 20/26/32 to 32/40/48px; a physics circle now intersects actual enemy hulls instead of filtering center positions. Ray checks preserve obstacle/armor occlusion and boss-group exclusions. The visual source/export grows to native 96px cells. Selection cards show base blast / +25% / +50% radius relative to rank one, without pixel units.

`PlayerHitSnapshot` owns the explicit source/modifier policy. Electric chains are allowed only for main/side cannon hits. Missile, drone and satellite snapshots discard the chain modifier, while explosion/critical support remains separately authorized. Plasma, reflected, secondary and unregistered sources receive no combat effects by default. Queue guards use the same policy; future effects/sources must opt in. This fixes the remaining satellite lightning path without per-weapon exclusion patches. See the updated [explosion](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/impact_explosions.md) and [chain evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/energy_chains.md).

### Final playtest tuning — 2026-10-22

The maintainer also excludes side shots from electric chains. Main and side emissions now have distinct source kinds under the same centralized policy, including both extra side shots at the final rank. Only the main cannon can trigger lightning; main-only wording appears on its card. Explosion radii shrink by 25% at every rank and damage doubles: 24/30/36px, 70/90/110% pre-critical damage. Percentage-based radius descriptions and real hull-overlap detection remain. Native explosion (171), chain (200), selection (48) and activation (76) checks pass; affected regressions and 93 editor diagnostic documents are clean. Stop for playtest before step 13.

### Approved expanding-wave correction — 2026-10-22

The latest maintainer-approved plan replaces the instant capped splash with a physics-timed wave. Radius begins at 25%, reaches its authored 24/30/36 maximum in 120ms, damages all overlapping additional hulls once through 160ms, then leaves inactive fragments until 320ms. Damage stays 70/90/110% pre-critical; owner cooldown stays 0.30s. Ordinary hulls no longer shield their neighbors. Chain and blast damage stack on ordinary enemies, while direct-origin and boss-group exclusions stay shared. Main-only lightning and the centralized source policy are preserved.

[Current wave evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/impact_explosion_wave.md) records 263 clean native checks, six moving enemies, both synergy orders, lifecycle/saturation, refreshed Aseprite art and clean diagnostics. Cards now describe an area rather than four targets. Stop for maintainer playtest before step 13; no commit/push is requested.

### Steel satellite revision — 2026-10-22

After accepting explosions for now, the maintainer approved metallic spiked satellites with a 1.25-second orbit and an independent 0.625-second spin. The first flat art draft was rejected during implementation; the delivered Aseprite MCP replacement has beveled steel cores, four tapered decorative spikes, asymmetric team inserts and separate editable source layers. Both icons match. Counts, radius-four core contacts, damage, cooldowns and main-only lightning remain unchanged. Final satellite **364 native checks**, affected regressions and **93 clean diagnostic documents** pass. See [current satellite evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/orbiting_satellites.md#steel-satellite-appearance-and-motion-revision--2026-10-22). Stop for this playtest; no ricochet work or commit/publication is included.

### Satellite rotation simplification — 2026-10-22

The maintainer requested one canonical satellite sprite per player, rotated by script. The runtime now rotates only Sprite2D continuously, retains reflection/contact frames and leaves the core collider unchanged. The Aseprite source has two team rows (16x32 frames, 128x32 sheet) rather than eight directions per team. Periods and combat remain unchanged. Native satellite 364 / explosion 263 checks and 93 clean diagnostic documents pass. See [current evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/orbiting_satellites.md#one-team-sprite-with-scripted-rotation--2026-10-22). Stop for satellite playtest.

### Defensive utility pack checkpoint — 2026-10-22

The maintainer-approved [defensive plan](../aidd_docs/tasks/2026_10/2026_10_22_defensive_pack/plan.md) is implemented locally. The former shield reward is now a three-rank sphere: 3/5/7 charges, recharge 8/6/4 seconds, radius 20, reverse-trajectory reflection, body and continuous-beam protection. Reactive armor adds +25/50/75% ordinary injury grace without longer slowdown/flash. Retaliation triggers on rupture/nonfatal injury: damage 2/3/4, radius 32/40/48, four-second owner cooldown, a synchronized 160ms active wave and inactive fragments through 320ms. It clears hostile shots without recursive effects. All three share existing utility slots; the catalog has 19 entries.

Original Aseprite art, both team cards/miniatures, compact event-driven HUD state and safe ownership/pooling ship together. [Evidence](../aidd_docs/tasks/2026_10/2026_10_22_defensive_pack/validation.md): 292 native defensive checks, affected weapon/progression/boss regressions, 102 clean diagnostic documents and exact asset audits. The full historical collision sweep retains documented preexisting failures; targeted foundation geometry passes. Stop for maintainer playtest. No commit/push, extra slots, broad balance or ricochet work is included.

### Retaliation emergency countermeasure — 2026-10-26

Historical checkpoint: the current defensive contract above supersedes its asteroid exclusion and shield priority.

The maintainer approved a defensive rework of Retaliation Pulse, then restricted its activation to direct enemy body contact: a ready charge cancels the next enemy collision threatening the hull, including a lethal one, and grants brief protection while releasing a stronger 360-degree counterattack. Enemy projectiles, beams and asteroid bodies cannot trigger it. Once activated, its short protection still covers all incoming damage. The reflector sphere takes priority; its rupture preserves the pulse for the next enemy hull collision. Initial playtest values are damage 4/6/8, radius 64/80/96, cooldown 12/10/8 seconds and 0.6 seconds of protection. This is a scoped Phase 3 utility revision; broad balance and ricochet remain deferred. See the [implementation and acceptance contract](../aidd_docs/tasks/2026_10/2026_10_26_retaliation_countermeasure/plan.md).

Implemented locally with ready/protected indicators, a larger synchronized wave and updated selection copy. The contact-only correction passes 263 headless and 350 native defensive checks, hull-contact and player-hit regressions, and native solo/co-op/wide captures. [Validation](../aidd_docs/tasks/2026_10/2026_10_26_retaliation_countermeasure/validation.md) also retains the preceding combat/progression regression results. Await maintainer playtest of the provisional values.

A follow-up [collision investigation](../aidd_docs/tasks/2026_10/2026_10_26_retaliation_countermeasure/collision_debug.md) reproduced brief enemy overlaps discarded before the post-movement contact query, including while the pulse was ready or cooling. Enemy callbacks now preserve confirmed unshielded contacts, and boss parts retain their actual surface identity. Hull-contact checks pass 75 headless / 81 native, with the 263 / 350 defensive checks and player-hit/boss-part regressions still passing. Protection duration and balance values are unchanged.

### Hull contact and build capacity checkpoint — 2026-10-22

The maintainer-approved [contact reliability plan](../aidd_docs/tasks/2026_10/2026_10_22_contact_reliability/plan.md) fixes the hunter's undersized stationary collision hull and prevents shield body cooldown from granting immunity after rupture. The player's forgiving central hitbox and last-impact absorption remain. Three offensive plus three utility slots now apply in data, offers, debug, personal co-op builds, selection and HUD; owned ranks remain upgradeable. No weapon category, damage, speed or sprite changes are included.

[Validation](../aidd_docs/tasks/2026_10/2026_10_22_contact_reliability/validation.md): 5,401 native checks pass, 104 diagnostic documents are clean and native contact/selection states are inspected. Seven historical hunter geometry failures disappear; 31 unrelated historical assertions remain, with no new errors. Playtest a fresh defensive build with the reduced offensive capacity before ricochet.

### Guard blades checkpoint — 2026-10-24

The maintainer-approved [guard blades plan](../aidd_docs/tasks/2026_10/2026_10_24_guard_blades/plan.md) adds the final requested close-range defensive attack as an ordinary offensive family. Two screen-up, player-following blades sweep the front over 280ms, then leave 120ms of inactive fragments. Ranks deal 2/3/4 damage at 3/2.5/2-second intervals; common DAMAGE applies once, FIRE_RATE does not. Both blades share one accepted hit per hull/boss group, clear covered hostile shots and respect armor. Crits, chains, explosions and ricochet never trigger. Reflected/friendly shots and continuous beams remain intact.

Original Aseprite effects, paired team cards/miniatures, ordinary offers/HUD slots, debug state and an optional empty audio hook are implemented locally. The live catalog has 20 entries and still enforces three offensive/three utility families. [Evidence](../aidd_docs/tasks/2026_10/2026_10_24_guard_blades/validation.md): 228 dedicated native checks, 5,323 native checks including affected regressions, 106 clean diagnostic documents, exact source/export/runtime texture parity and all nineteen prior atlas columns preserved. Stop for guard-build playtest before ricochet; no new commit/push or broad balancing is requested.

Guard-blade size playtest revision: outer reach is now 60 instead of 44 (+36.4%), with the inner gap still 16 and unchanged damage/timing. MCP Aseprite effects and guard icons match the new geometry. The refreshed dedicated fixture passes 240 native checks, including hull damage and hostile-shot clearing in the added reach; palette/export/import audits pass. Stop for the next maintainer playtest.

The next maintainer-requested guard revision supersedes that fixed reach: ranks now reach 60/72/84 (+0/+20/+40%) at 3/2/1.5-second start intervals, preserving the inner gap and damage. A tiny personal bar fills above the ship in the last 0.6 seconds before activation, including acquisition; recurring warnings fit inside the interval. It has no numeric time or text. Native rank art, card percentages and tests are updated. Fresh 280 guard, 3,781 offer and 51 selection checks pass; 106 diagnostic documents and art/export/import audits are clean. Stop for playtest before ricochet.

Guard convergence follow-up (2026-10-25): both arcs end at -90 degrees, superimposing screen-up instead of crossing beyond each other. Their geometry and animation share this new endpoint; other values stay unchanged. All 286 refreshed native guard checks pass, including equal final rotation/center/frame at every rank, with inspected convergence/cooling captures. Stop for playtest before ricochet.

Visible meeting correction after playtest feedback: the endpoint-only change aligned the arcs too late, when the bright edge vanished. They now converge in 160ms and remain identically superimposed, bright and active for 120ms. MCP Aseprite terminal/cooling frames and right-hand mirroring match this hold; damage/cadence/reach and total lifetimes stay unchanged. Fresh 300 guard and 3,781 offer checks pass, 106 diagnostic documents are clean, and palette/source/export/import audits pass. A native before/after preview is recorded in the guard evidence. Stop for the next maintainer playtest.

### Upgrade category choices — 2026-10-25

The maintainer requests visible categories and an offensive/utility choice at every level. All cards now identify OFFENSIVE or UTILITY; consumable energy identifies RECOVERY. Every personal hand reserves an eligible offensive and utility whenever both categories remain available, including rank upgrades at full slot capacity. Existing acquired/new guarantees, three distinct offers, slot limits, weighted draws and co-op RNG isolation remain. Exhausted categories yield only the remaining eligible offers. See [category validation](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/upgrade_categories.md). Stop for playtest before ricochet.
