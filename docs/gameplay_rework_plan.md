# Gameplay roadmap

Updated: 2026-10-21.

**Goal:** a continuous survival shmup with varied builds, enemies and formations, increasing pressure over time, solo and local co-op.

**Next step:** Review playable step 9, escort drones, before requesting step 10, orbiting satellites. Steps 1-4, 6-9 and standalone step 12 chains are implemented. Missiles and drone bolts retain criticals but are explicitly excluded from electric chains; piercing belongs to the manual signature beam. Explosion coexistence remains with step 11. Step 5 still needs two solo observations and qualitative feedback. The maintainer explicitly defers effect balancing; prototype values remain recorded. Dedicated selection audio remains pending. See [Phase 3 evidence](phase_3_validation.md).

## Progress and delivery order

| Phase | Scope | Status |
| --- | --- | --- |
| Preparation, Phase 1 and art | Original identity, display, core combat, controls, plasma and graphics | Complete |
| 2 — Continuous survival | Seeded encounters, elites, first boss, survival UI and records | Complete; solo accepted, co-op playtest deferred |
| 3 — Experience and power-ups | XP, personal builds, original weapon sprites and audiovisual level-up choices | In progress; steps 1-4, 6-9 and standalone 12 implemented; plasma piercing, criticals, chains, micro-missiles and escort drones playable; human XP acceptance deferred |
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

The [detailed plan](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/plan.md) and its [delivery contract](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/contract.md) record the maintainer's direction and prototype values. Steps 1-4, 6-9 and standalone 12 are implemented. Automated XP measurement exists; human calibration acceptance and later offensive families remain pending. Execute only the requested numbered step, then verify and stop for review.

Replace direct drops with pooled XP and paused choices inspired by Vampire Survivors / Megabonk. Share XP in co-op with personal offers and four offensive plus three utility family slots per player. Acquired families stay for the run; rarity remains deferred.

Nomad retains its native manual secondary plasma beam and reserve, outside the offensive slots. Future ship signatures remain planning-only; no ship selection or permanent progression is included.

Prepare dormant models and a complete animated selection screen before activating XP, rewards, foundation ranks and HUD together. Deliver each offensive family in bounded checkpoints with editable sources, runtime sprites and native visual verification. Following the maintainer's playtest, piercing belongs to the manual plasma beam as a utility. The cannon's nearest-target electric arc is now playable: 1/2/3 other targets within 72/88/104 px, 45% pre-critical damage per jump and a 0.5-second personal cooldown. Obstacles block the links; secondary effects cannot recurse. Satellites, explosions and ricochets remain pending. See [chain evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/energy_chains.md).

The three beam-piercing ranks cross 1/2/3 extra targets, add 20/30/40% initial damage and raise normal width from 8 to 10/11/12 px (overdrive 20/22/24 px). Each crossed target reduces subsequent damage and width to 80%. These prototype bonuses apply only with this utility, occupy one utility slot, grant no plasma and preserve manual drain and armor blocking. See [beam verification](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/beam_piercing.md).

Include refreshed player lasers, XP and dedicated plasma-cell sprites, upgrade icons and a strong level-up opening. Plan one musical sting/selection loop session per queued-level batch, with gameplay music resuming at its previous position. Follow the [selection audio scope](sound_design_plan.md#phase-3-selection-moment--brief-verified-2026-10-20) for production/listening; the full MusicDirector workstream remains separate.

First playable feedback (2026-10-20): XP orbs now use visible pulsing gold halos, with larger halos for high-value pickups. Retain the shared level and its progress bar in the HUD, without a numeric XP counter. Halos fade radially from ivory through gold to transparent amber; XP thresholds and selection information are unchanged.

Further approved follow-ups: 64px Nomad effect illustrations and matching 16px team miniatures; two three-rank utility families for plasma capacity (+25 per rank, up to 175) and cell recovery (+25% per rank, up to x1.75). They share the three utility slots, preserve current charge on acquisition, and retain manual beam drain/full-reserve overdrive. XP collection now plays a short dedicated procedural ping on Sounds, with bounded burst playback. These additions are playable prototypes; economy calibration and human audio/balance acceptance remain pending.

Verify that different choices produce different, useful builds before redesigning enemy pressure.

Micro-missiles fire autonomously at nearby visible targets, including during manual cannon or plasma use. Three ranks provide 1/2/3 missiles per volley, increasing native sprite sizes, damage 0.9/1.1/1.3 and intervals 1.10/0.95/0.80 seconds before common DAMAGE/FIRE_RATE adjustments. Each owner has at most three active/reserved missiles, speed 240 px/s, turn limit 240 degrees/s, one reacquisition and 1.8-second lifetime. Physical impacts can critically strike but cannot trigger electric chains, piercing or ricochet; no intrinsic splash. Dedicated body/thrust/impact and card art ship together. See [missile evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/micro_missiles.md).

Latest missile targeting revision: acquisition, target retention and reacquisition are restricted to the 90-degree screen-up cone. Rear/lateral enemies cannot trigger a launch or pull a missile into a U-turn. Cannon chains retain their existing targeting.

### Step 9 escort checkpoint — 2026-10-21

Escort drones fire straight aimed bolts independently of manual cannons/plasma. Ranks provide one / one / two companions (second drone at rank three), damage 0.6 / 0.75 / 0.9 and intervals 0.65 / 0.55 / 0.45 s before the common stat factors. Six active/reserved bolts are shared per owner; range is 180 px within a 90-degree screen-up cone (+/-45 degrees), speed 360 px/s and lifetime one second. Hulls bank with Nomad movement; reduced copies of its twin reactor effect share the current smoothed movement response and team palette. Visual emitters tuck inside the arena at the edges while player movement bounds remain unchanged. Drone impacts cannot trigger electric chains or consume the cannon chain cooldown; direct criticals remain available. Pause freezes support/flight; DYING removes both companions and cancels new owned emissions/procs. See [escort evidence](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/validation/escort_drone.md). Balancing remains deferred.

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
