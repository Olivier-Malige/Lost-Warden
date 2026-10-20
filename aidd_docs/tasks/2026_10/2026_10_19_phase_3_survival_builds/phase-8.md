---
status: pending
---

# Instruction: Add bounded homing micro-missiles and their complete sprite delivery

## Architecture projection

> Tree of the final files. ✅ create · ✏️ modify · ❌ delete

```txt
.
├── data/upgrades/micro_missiles.tres                        ✅ authored ranks and projectile reference
├── data/upgrades/foundation_catalog.tres                   ✏️ completed-family registration
├── scenes/player/weapons/{micro_missile.gd,micro_missile.tscn} ✅ pooled homing projectile
├── scenes/player/{player,player_weapons,player_loadout}.gd  ✏️ autonomous cadence and owner lifecycle
├── scenes/combat/{combat_targeting,player_hit_snapshot,player_hit_effects}.gd ✏️ compatible direct hits
├── scenes/combat/projectile_pool.gd                        ✏️ active/reserved lifecycle if needed
├── assets/sources/player/weapons/micro_missile.aseprite     ✅ body, thrust and impact master
├── assets/sprites/player/weapons/micro_missile_sheet.{png,json} ✅ matching runtime export and mapping
├── tests/player/test_micro_missiles.gd                     ✅ guided-flight and cap fixtures
├── aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/art_audio_inventory.md ✏️ mapping and review
└── docs/phase_3_validation.md                              ✏️ append actual evidence
```

## User Journey

```mermaid
flowchart TD
  A[Choose micro-missiles] --> B[Autonomous timer becomes ready]
  B --> C{Eligible target and free capacity}
  C -->|No| B
  C -->|Yes| D[Emit one owned missile with a direct-hit snapshot]
  D --> E[Turn toward its target within the authored rate]
  E --> F{Target lost}
  F -->|First loss| G[Try one deterministic reacquisition]
  F -->|No| H[Continue physical flight]
  G --> H
  H --> I[Impact, expiry or screen exit returns the missile to its pool]
```

## Test Scope

```mermaid
---
title: Test scope
---
journey
  section Setup
    Prepare seeded moving targets and two personal builds => known acquisition order: 5: cli
  section Happy path
    Hold no manual fire => missiles emit at authored adjusted intervals: 5: system
    Move a target sideways => measured trajectory obeys speed and turn limits: 5: system
    Contact a valid enemy => direct damage and critical compatibility are correct: 5: system
  section Edge case - Lost target
    Target is destroyed during flight => attempt one reacquisition => later loss yields straight bounded flight: 1: system
  section Edge case - No target or saturated cap
    Targets disappear or three entries are active and reserved => advance timers => no extra missile or stored burst: 1: system
  section Edge case - Owner and world lifetime
    Owner enters DYING or world is removed => advance deferred work => no new owned emission survives: 1: system
  section Teardown
    Pause, resume and repeat restarts => timers freeze correctly and counts recover: 5: system
```

## Tasks to do

### `1)` Add the autonomous emitter and pooled flight

> Use the missile ranks, targeting rules and fixed limits from `contract.md`.

1. Extend the existing `PlayerWeapons` update path so missile readiness advances while the living owner is not manually firing or is using plasma. No new autoload, slot type or input action is required.
2. Acquire the nearest eligible visible target from the emitter, with stable tie-breaking; retain it until invalid. On first loss, permit one acquisition within range from the missile's current position, then fly straight after failure or a later loss.
3. Enforce speed, angular turn limit and lifetime through actual flight. Collisions, including armor, resolve physically; a missile does not teleport damage to its target and has no intrinsic splash.
4. Count active plus reserved missiles per owner against the cap. No target leaves one ready emission; a saturated cap skips that opportunity without backlog. Snapshot common DAMAGE once and scale cadence by FIRE_RATE exactly as contracted.

### `2)` Integrate ownership, modifiers and artwork

> Missiles are direct sources, with complete art rather than an enemy-projectile recolor.

1. Route accepted hits through the common snapshot/effects service. Enable critical hits; keep piercing and ricochet disabled for missiles. Preserve the future explosion/chain extension points without exposing unfinished cards.
2. Stop new emissions and procs at owner DYING; existing missiles finish their bounded lives. Cancel reserved/deferred emissions on owner/world invalidation and clear target, turn state, reacquisition latch and ownership on reuse.
3. Deliver source plus PNG/JSON for the body, propulsion and impact; update `art_audio_inventory.md` with anchors/tags and team variants. Inspect the native silhouette against both player lasers and enemy missiles; palette-check exports.

### `3)` Validate and activate the family

> Demonstrate guidance and independent co-op caps in the running physics world.

1. Test all ranks and FIRE_RATE/DAMAGE extremes, critical emission traces, no-target readiness, cap saturation, real armor/boss contacts and one-time reacquisition. Measure movement over fixed simulation steps rather than merely reading configured values.
2. Verify P1/P2 counters and snapshots independently, pause freezes guidance/cadence/lifetime, and repeated death/restart releases reservations and roots. Recheck manual fire and signature plasma behavior.
3. Enable the completed family in offers, append actual runtime/art evidence and stop for review before adding the drone.

## Test acceptance criteria

| Task | Acceptance criteria |
| ---- | ------------------- |
| 1 | Measured emission intervals, direct damage, speed, turn rate and lifetime match the contract at all ranks. Acquisition is deterministic, reacquisition happens at most once, and no owner exceeds three active/reserved missiles or receives a backlog burst. |
| 2 | Missile hits can critically strike but cannot pierce, ricochet or splash without a later applicable family. Armor and logical boss groups remain effective; pooling and deferred owner invalidation leak no state. Source/export pairs and native visual review are complete. |
| 3 | Actual-contact, flight, co-op ownership and pause/restart fixtures pass with bounded counts. The card uses personal slot eligibility and only becomes available after its implementation; manual primary/plasma behavior remains compatible. |
