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
| **State** | Steps 1-4, 6-9 and standalone step 12 are implemented, including beam piercing, following electric chains, autonomous micro-missiles and movement-reactive escort pairs. Step 5 has 800 measured simulations and one solo observation; two runs and qualitative feedback remain pending. Steps 10-11, 13-14, future explosion coexistence and dedicated selection audio remain pending. Effect balancing is explicitly deferred. |

On 2026-10-20 the maintainer explicitly requested publication and the next step. The foundation and step 6 are published on `codex/phase-3-survival-builds`. After reviewing step 6, the maintainer requested the next step: [step 7 piercing and critical hits](validation/step_7_piercing_criticals.md) are implemented and verified locally while step 5's remaining human acceptance stays deferred. One actual seed-69 run reached five choices; this does not replace the missing observations or qualitative feedback. No XP numerical target is silently revised.

**Latest maintainer revision, 2026-10-21:** piercing moved from the cannon to its manual plasma signature; the [beam revision](validation/beam_piercing.md) provides three utility ranks and 80% retained width/damage per crossed target. The cannon's [electric chains](validation/energy_chains.md) follow their enemies visually. [Step 8 micro-missiles](validation/micro_missiles.md) now has smaller native sprites growing by rank and 1/2/3-projectile volleys. Missiles retain criticals but are explicitly excluded from electric chains after playtest. Step 11 retains future explosion coexistence. The maintainer accepted the missile checkpoint, requested commit `30818a6` and authorized step 9. Escort drones now bank and thrust with Nomad, and rank three adds the second companion while retaining the six-bolt owner cap. Stop after escort review; orbiting satellites are next. Effect balancing remains deferred.

Maintainer-approved playable follow-ups on 2026-10-20 add plasma reserve/recovery utility families, 64px Nomad effect cards with matching 16px team miniatures, and a dedicated procedural XP pickup ping. The charge families occupy the existing three utility slots and use prototype values recorded in the contract. This expands the live catalog to ten entries without starting step 5 or changing encounter pressure. Dedicated selection music/sounds and human listening acceptance remain pending; the XP ping is an agent-authored requested prototype rather than a supplied master.

The concise roadmap remains the source of delivery order. These numbered files are steps inside gameplay Phase 3, not new roadmap phases. On 2026-10-20 the maintainer authorized local commits, updating the principal branch from origin, rebasing, publication and proceeding to the next checkpoint. Earlier commits, the conflict-free rebase onto freshly pulled `origin/master`, and publication through step 6 are complete. No merge into master is requested. Step 5 measurement and its pending acceptance are recorded in [the economy evidence](validation/step_5_economy.md); later combat families remain separate checkpoints.

The maintainer approved the silent interactive preview and requested implementation on 2026-10-20. The selected visual direction is **Arsenal déployé** (horizontal solo cards; personal stacked co-op cards). Steps 1-4 are complete: [verified inventory](art_audio_inventory.md), [selection audio brief](selection_audio_brief.md) and [evidence](../../../../docs/phase_3_validation.md). Step 5 still needs two solo observations and qualitative feedback after automated measurement and its first actual run. Steps 6-9 and standalone 12 are delivered under explicit instructions to proceed. No XP numerical change is retained; steps 10-11, 13-14 and future combined-proc acceptance remain pending. Phase 3 is not complete. The maintainer supplies dedicated selection audio; no files have been supplied. The requested XP pickup ping is an agent-authored prototype with its source generator in the repository. Dedicated audio/listening remains pending.

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
