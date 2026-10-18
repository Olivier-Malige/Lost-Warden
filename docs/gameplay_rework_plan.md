# Gameplay roadmap

Updated: 2026-10-18.

**Goal:** a continuous survival shmup with varied builds, enemies and formations, increasing pressure over time, solo and local co-op.

**Next step:** Phase 2 — final solo/co-op gameplay validation.

## Progress and delivery order

| Phase | Scope | Status |
| --- | --- | --- |
| Preparation, Phase 1 and art | Original identity, display, core combat, controls, plasma and graphics | Complete |
| 2 — Continuous survival | Seeded encounters, elites, first boss, survival UI and records | In progress |
| 3 — Experience and power-ups | XP orbs, level-up choices and a much broader upgrade catalog | Planned |
| 4 — Enemies and density | Redesign current enemies, add roles, enrich formations, increase pressure over time | Planned; after Phase 3 |
| 5 — Combat effects | Impacts, explosions, collections and upgrade feedback | Planned |
| 6 — Final balance | Complete solo/co-op runs, performance and regression checks | Planned |

## Phase 2 — Finish the survival foundation

Done: continuous seeded encounters, threat budgets, formations, enemy caps, survival timer, solo/co-op duration records, game-over and hiscore screens. Deterministic elites now have approved markings, a small health bar and a three-elite cap. Danger stays internal. F1/F2 adjust danger; N skips a regular encounter in debug mode.

New runs leave three seconds before the first formation, in solo and co-op. Pause freezes this opening respite; subsequent encounters retain their normal timing.

The Dread Ark has two phases, switching at 50% health. Phase one cycles rings, aimed salvos, spirals, aimed salvos and drones; phase two adds a dedicated beam attack. Rings keep a 30-degree opening; spirals alternate rotation with 16 / 20 emissions, and circular missiles travel more slowly than aimed salvos. Core health remains 650 solo / 1,040 co-op; cannons have 90 / 144 HP. Faster seeded repositioning combines acceleration, braking, short rests and height changes; beams lock its position. Its health bar has two segments without numeric health or phase text. Five-minute milestones and eight-second recovery remain in place.

Natural milestones enter `BOSS_APPROACH`: stop new formations, preserve existing enemies, asteroid fragments and enemy shots, then wait for an empty arena and 0.5 seconds of calm. Survival time continues; regular scheduling and the calm window respect pause. F12 retains immediate debug cleanup.

Rings and spirals emit round red energy balls from the central cannon mouth, with a local charge/fire/recovery effect and continuous phase hull animation. Aimed salvos retain elongated missiles. The new editable Aseprite assets use Lost Warden 64 exclusively. Attacks retain their charging animations without projected ring guides or beam-lane indicators.

Two optional destructible cannons have independent health, local shader hit feedback and persistent wrecks. Each destroyed cannon loses its targeted salvos and lateral beam; the core retains circular patterns and its wide central beam. Drone launches contain four solo / six co-op hunters, capped at eight / twelve including reservations; incomplete groups are skipped. Phase changes cancel pending launches and active boss missiles. Defeat chains hull explosions into a large final blast and strong screen shake.

Boss beams deal one energy point on contact and every 0.35 seconds of continued exposure, with independent player cooldowns. Leaving the damage core stops further drain.

Six regular encounter types now mix formation drones with hunters using distinct arrowhead interceptor sprites, dark neutral hulls and red sensors matching the boss palette; elites have amber armor. Their hull and exhausts face their actual velocity. Hunters pursue at 175 px/s, commit to a straight attack 64 pixels before reaching the player, then progressively turn downward after crossing the height locked at commitment. Boss reinforcements share this behavior and appearance.

Player beams stop at the first impact, damage only that obstacle and extend to the next target when it is destroyed. Boss armor, core and cannons use their own collision surfaces.

Debug tools: **F11** toggles compact metrics; **F10** opens the [paused full inspector](debug_screen.md); **F12** starts a boss immediately during active gameplay.

Remaining, one step at a time:

1. Playtest the revised boss and complete solo/co-op acceptance before Phase 3.

## Phase 3 — Create varied survival builds

Replace direct power-up drops with XP orbs and paused level-up choices. Share XP in co-op; each living player chooses their own upgrades.

Expand beyond speed, damage, fire rate, side shots, attraction, repair and shields. Candidate new effects: piercing, ricochets, homing missiles, explosions, energy chains, escort drones, orbiting satellites and critical hits. Define mechanics and ranks before implementing each group.

Verify that different choices produce different, useful builds before redesigning enemy pressure.

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
