---
objective: "Deliver shared XP, personal survival builds, synchronized original weapon art and a rewarding paused level-up presentation while preserving Nomad's plasma signature."
status: in-progress
---

# Plan: Phase 3 survival builds and level-up presentation

## Overview

| Field | Value |
| --- | --- |
| **Goal** | Make collected XP lead to readable, useful choices and distinct temporary builds, with original sprites and a satisfying audiovisual selection moment. |
| **Source** | Maintainer planning requests and choices on 2026-10-19; docs/gameplay_rework_plan.md and its Phase 3 technical reference. |
| **Contract** | [Product, mechanics, art, audio and verification contract](contract.md) |
| **State** | Steps 1-4 completed on 2026-10-20. The first playable foundation includes shared XP, personal choices, native UI/HUD, safe pooled orbs and paired art. Measured calibration, later offensive families and dedicated audio remain pending. |

Maintainer-approved playable follow-ups on 2026-10-20 add plasma reserve/recovery utility families, 64px Nomad effect cards with matching 16px team miniatures, and a dedicated procedural XP pickup ping. The charge families occupy the existing three utility slots and use prototype values recorded in the contract. This expands the live catalog to ten entries without starting step 5 or changing encounter pressure. Dedicated selection music/sounds and human listening acceptance remain pending; the XP ping is an agent-authored requested prototype rather than a supplied master.

The concise roadmap remains the source of delivery order. These numbered files are steps inside gameplay Phase 3, not new roadmap phases. On 2026-10-20 the maintainer explicitly authorized continuing through a first playable version: verify step 3, then deliver step 4's atomic foundation activation before the next review. Later combat families and economy calibration remain their separate checkpoints. No commit, merge or publication is authorized. Existing local changes remain the working baseline.

The maintainer approved the silent interactive preview and requested implementation on 2026-10-20. The selected visual direction is **Arsenal déployé** (horizontal solo cards; personal stacked co-op cards). Steps 1-4 are complete: [verified inventory](art_audio_inventory.md), [selection audio brief](selection_audio_brief.md) and [evidence](../../../../docs/phase_3_validation.md). Step 5 is next: measure collected XP before changing its economy. Steps 5-14 remain pending; Phase 3 is not complete. The maintainer will provide all music and sound effects; no dedicated selection audio files have been supplied. The later requested XP pickup ping is an agent-authored prototype, with its source generator in the repository. Existing menu cues support the playable selection and local music ownership is tested, while dedicated audio/listening remains pending. The agent handles later import, loop preparation, mix levels and integration.

Confirmed direction: Vampire Survivors / Megabonk-style XP, choices and synergies; four offensive plus three utility families; personal co-op builds with shared XP; no replacement within a run. Nomad keeps the current manual secondary plasma beam, its reserve and overdrive, outside offensive slots. Rarity, weapon evolution, future ships and permanent progression remain deferred. Human co-op balance acceptance stays in Phase 6, after the power-up and balance rework.

The contract fixes mechanics and initial prototype values. Numerical tuning must be supported by measurements and recorded explicitly. New effects enter the live catalog only when fully implemented. Steps 1-3 prepare data, art direction and a tested selection component while retaining current live drops; step 4 activates the complete new loop at once. Every combat delivery includes editable art, exports and native visual evidence.

## Phases

| # | Phase | File |
| --- | --- | --- |
| 1 | Ground the art/audio inventory and production brief | [phase-1.md](phase-1.md) |
| 2 | Build dormant progression, slots, foundation ranks and offers | [phase-2.md](phase-2.md) |
| 3 | Compose pause, selection UI and audiovisual opening | [phase-3.md](phase-3.md) |
| 4 | Deliver pooled XP and foundation sprites; activate the complete loop | [phase-4.md](phase-4.md) |
| 5 | Calibrate collected XP without changing enemy pressure | [phase-5.md](phase-5.md) |
| 6 | Establish accepted-hit ownership, targeting and pooled snapshots | [phase-6.md](phase-6.md) |
| 7 | Deliver piercing and critical hits with their art | [phase-7.md](phase-7.md) |
| 8 | Deliver homing micro-missiles with their art | [phase-8.md](phase-8.md) |
| 9 | Deliver the escort drone with its art | [phase-9.md](phase-9.md) |
| 10 | Deliver orbiting satellites with their art | [phase-10.md](phase-10.md) |
| 11 | Deliver bounded impact explosions with their art | [phase-11.md](phase-11.md) |
| 12 | Deliver bounded energy chains with their art | [phase-12.md](phase-12.md) |
| 13 | Deliver bounded ricochet shards with their art | [phase-13.md](phase-13.md) |
| 14 | Verify builds, economy, performance and final audiovisual acceptance | [phase-14.md](phase-14.md) |

## Resources

| Source | Verified |
| --- | --- |
| [Megabonk official store page](https://store.steampowered.com/app/3405340/Megabonk/) | XP collection, level-up choices, growing power and synergistic builds are relevant inspiration; its rarity system is not adopted. |
| [Vampire Survivors official store page](https://store.steampowered.com/app/1794680/Vampire_Survivors/) | Escalating power through player choices is the intended progression reference; retain Lost Warden's own identity and controls. |

## Decisions

| Decision | Why |
| --- | --- |
| Keep the signature plasma beam native, manual and outside build slots. | The maintainer confirmed it defines Nomad; retaining its reserve preserves combat decisions and avoids a future-ship implementation. |
| Separate pure run progression from personal PlayerLoadout state and UI snapshots. | Shared XP must not imply shared equipment or UI-to-player coupling. |
| Centralize pause ownership in main before enabling selection. | Existing menu, debug and transition paths otherwise release another feature's pause. |
| Prepare dormant pieces, then activate XP/rewards/selection together. | Avoid shipping XP with no usable choice screen or breaking old drops halfway through migration. |
| Bound secondary effects per owner and forbid recursive procs. | Four offensive families can combine without projectile/area-hit explosions or multipart boss damage multiplication. |
| Produce sprites inside their feature checkpoints; the maintainer supplies music and sound effects. | Visual identity is part of Phase 3. The agent handles audio import, loops, mix levels and integration; final audio needs supplied exports and listening acceptance, while the current preview stays silent. |
| Keep rarity, permanent progression, full MusicDirector work and enemy-density redesign outside Phase 3. | These are distinct systems/workstreams and would obscure whether the new progression works. |
