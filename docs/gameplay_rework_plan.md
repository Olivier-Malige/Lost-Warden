# Dynamic Gameplay Rework Plan

## Summary

Evolve the existing game on `codex/dynamic-gameplay-rework` through two preparation phases followed by six independently verifiable gameplay phases. Keep the current repository and the existing itch.io project so the game-jam history, audience, and working code are preserved. A separate replacement repository is not required. Every phase must leave the game playable before the next phase starts.

The final target is:

- an uninterrupted run that ends when every player is dead;
- an original space-opera universe and release identity that can replace the current game-jam presentation;
- a full-viewport presentation without the decorative computer frame or legacy background ships, plus a responsive Web build suitable for itch.io;
- an initial gameplay pace roughly 20% faster than the current game;
- deterministic procedural encounters driven by an internal seed;
- experience orbs and upgrade choices instead of direct random power-ups;
- shared experience with individual builds in co-op;
- difficulty driven primarily by encounter variety and density;
- visible elite enemies and recurring milestone boss encounters;
- three new enemy roles, improved movement, particles, and shaders.

Permanent meta-progression, unlockable ships, profile levels, and account-wide upgrades are explicitly deferred to a separate future plan. This rework must keep stable data identifiers so those systems can be added without coupling unlocks to file paths or display text.

## Progress

- Phase 0: completed.
- Preparation phase A: completed and approved.
- Preparation phase B: completed and approved on 2026-08-28.
- Next implementation phase: Phase 1 — Increase the core gameplay pace.

Preparation phase B delivered the direct 1066 by 800 viewport, responsive Web presentation, redesigned menus and HUD, browser-fullscreen recovery, the Lost Warden release identity, the approved 24-color palette, itch.io page art, and a validated release archive. Updated gameplay screenshots remain intentionally deferred until the sprite rework is visible. Candidate replacement music is preserved for later review and is not active in the current build.

## Phase 0 — Track and commit the roadmap

- Create `codex/dynamic-gameplay-rework` from the current HEAD.
- Store this roadmap in `docs/gameplay_rework_plan.md`.
- Reference this roadmap from `AGENTS.md` and keep the future meta-progression work planning-only.
- Preserve the existing local change in `scenes/main/main.tscn` and exclude it from the roadmap commit.
- Commit only `AGENTS.md` and this document as `docs: add dynamic gameplay rework plan`.

Deliverable: a versioned roadmap with no gameplay changes in the commit.

## Preparation phase A — Design the original universe and rebrand path

- Continue from the current game and codebase instead of rebuilding the project from scratch.
- Preserve the last game-jam-compatible state with an identifiable Git tag or release reference before identity-changing implementation begins.
- Create `docs/universe_bible.md` in English and obtain maintainer approval before producing replacement art. It must define:
  - the core premise, tone, themes, and three to five creative pillars;
  - a working codename and a shortlist for the final original title;
  - the player role, central conflict, major factions, and their motivations;
  - original terminology for pilots, powers, weapons, ships, locations, and resources;
  - a visual language for each faction, including shape grammar, palettes, materials, emblems, propulsion, and projectile styles;
  - audio and interface direction that supports the new 8-bit universe.
- Create an asset and terminology migration inventory covering the title, project metadata, source identifiers, ships, enemies, backgrounds, icons, audio, UI, screenshots, and itch.io store copy.
- For every legacy reference, record its replacement, whether code compatibility requires a temporary alias, and the phase in which it will be replaced.
- Separate mechanical reuse from fictional identity: retain proven gameplay code where practical, but redesign names, silhouettes, presentation, and lore.
- Do not mass-rename files or identifiers until the migration inventory has been reviewed, because paths are referenced dynamically in the current project.
- Stop extending legacy-specific names or designs once this phase is approved.

Validation:

- The universe bible is sufficient to design a player ship, three enemy families, an elite, and a boss within one coherent original visual language.
- Every public-facing legacy reference has an explicit disposition in the migration inventory.
- The maintainer has approved the creative pillars, working codename, and first faction design language.

Planned commit:

- `docs: define original universe and rebrand path`

## Preparation phase B — Remove the screen frame and clean up the Web presentation

Status: completed and approved on 2026-08-28. Gameplay screenshots and music activation are explicitly deferred as recorded in the progress section.

- Treat the existing itch.io project as the release destination for the evolved game. Keep its continuity, followers, and devlog history instead of creating a replacement page.
- Keep the current game-jam Web build playable while the rework is private. When the rebranded version is ready, make it the primary embedded Web build and preserve the final game-jam edition as a clearly labeled legacy download linked to its Git tag or release.
- Publish itch.io devlogs for the universe reveal, gameplay milestones, rebrand, and release. Explain that the project grew from the original game-jam entry without presenting the rework as a separate sequel.
- Update the itch.io title, page art, description, screenshots, downloadable filenames, and embedded build together with the first rebranded public build.
- Audit and remove only demonstrably unused scenes, scripts, assets, inputs, resources, and export settings. Verify references before deletion and keep cleanup separate from gameplay changes.
- Replace the project name, icon, export filenames, and remaining public-facing legacy terminology after the new title is approved.
- Remove the decorative computer/television frame, its border masks, and the X-wing, TIE, and Death Star light groups from the main presentation.
- Remove the camera zoom transition between the outside computer view and its internal screen. Present the title, menus, gameplay world, pause overlay, and game-over screen directly in one full logical viewport.
- Derive and document the new logical viewport from the current playable area before moving nodes. Update player bounds, spawn positions, background coverage, HUD anchors, and menu layout as one coordinated change.
- Delete `background_tv.png` and the decorative light scenes only after confirming that no retained scene references them.
- Keep operating-system fullscreen as an independent user preference; it is not the objective of this phase and must not affect gameplay coordinates.
- Make the Web canvas responsive inside the itch.io embed. Preserve the logical game aspect ratio, avoid non-uniform stretching, and use letterboxing or pillarboxing when necessary.
- Expose browser fullscreen through an explicit player action because Web fullscreen requires a user gesture. Do not make browser fullscreen a prerequisite for playing.
- Audit UI anchors and gameplay bounds at common 4:3, 5:4, 16:9, 16:10, and ultrawide window shapes while keeping the intended 8-bit pixel scale and readable HUD margins.
- Keep the GL Compatibility renderer and validate keyboard and gamepad focus in the embedded Web build.
- Produce a local release Web export and complete an itch.io draft-page smoke test before replacing the public build.

Validation:

- No computer casing, frame border, X-wing, TIE, or Death Star decoration remains around the game viewport.
- Starting a run no longer zooms the camera into a simulated screen.
- Every menu and gameplay layer fills the logical viewport, and player movement and enemy spawning use its visible bounds.
- The existing operating-system fullscreen preference still works, can return to windowed mode, and remembers the setting.
- The Web build remains playable without browser fullscreen and resizes without distorted sprites, clipped menus, or unreachable gameplay space.
- Solo and local co-op controls work after entering and leaving browser fullscreen.
- A clean export loads without missing resources, parser errors, console errors, or references to removed files.
- The public update checklist contains the rebranded title, page assets, description, screenshots, credits, license notices, and Web archive.

Planned commits:

- `chore: remove unused legacy resources`
- `feat(display): improve fullscreen and Web scaling`
- `chore(release): prepare rebranded Web build`

## Phase 1 — Increase the core gameplay pace

- Increase player base speed from 300 to 360, world scrolling from 140 to 168, and base fire delay from 0.26 to 0.22 seconds.
- Increase base enemy travel speeds by roughly 20% and enemy projectile speed by 10% to preserve readability.
- Remove the movement penalty while charging the beam.
- Keep the short movement penalty caused by taking damage.
- Stop resetting the loadout when a player takes damage.
- Keep run upgrades until the run ends.

Validation:

- Player movement speed is identical with and without beam charge.
- Taking damage does not remove any upgrade.
- Movement, shooting, and collisions remain readable in solo and co-op.

Planned commits:

- `feat(player): increase gameplay pace`
- `fix(player): preserve beam mobility and upgrades`

## Phase 2 — Add the seeded encounter director, elites, and bosses

- Turn the current waves into weighted encounters lasting 20 to 30 seconds and chain them without a gameplay break.
- Extend wave resources with a stable identifier, danger range, selection weight, threat budget, and formation data.
- Give every enemy family a threat cost, minimum danger, maximum danger, and weight curve. As danger rises, the director must spend a larger budget and progressively favor interceptors, turrets, mother ships, and later enemy families without removing common enemies completely.
- Add line, V, scatter, alternating-edge, and offset-group formations.
- Prevent either of the previous two encounters from repeating when another eligible encounter exists.
- Centralize encounter timers and remove obsolete timer nodes and signal connections from the world scene.
- Generate one internal seed per run and derive four independent random streams for encounters, enemy initialization, orb drops, and upgrade offers.
- Keep cosmetic randomness separate so graphics quality cannot alter seeded gameplay.
- Use the following danger curve:
  - start: 1.0;
  - 2 minutes: 1.4;
  - 5 minutes: 2.4;
  - 8 minutes: 3.4;
  - 10 minutes: 4.2;
  - 12 minutes: 5.0;
  - after 12 minutes: +0.2 per minute.
- Cap scaling at 1.5x enemy health, 1.2x additional enemy movement speed, and 0.8x firing delays.
- Cap active enemies at 70 in solo and 90 in co-op.
- Add deterministic elite promotion for eligible non-boss enemies:
  - no elites before 2 minutes;
  - 5% promotion chance at 3 minutes;
  - 10% at 5 minutes;
  - 18% at 8 minutes;
  - maximum 25% at 12 minutes and beyond;
  - no more than one elite per formation and three active elites at once.
- Give elites 2.5x health, 1.1x movement speed, 0.8x firing delays, 3x score, and a guaranteed high-value XP drop once Phase 3 is active.
- Make elites immediately recognizable with a palette-shifted outline, a pulsing aura, and a compact health bar. Their collision shape must not scale with the visual effect.
- Add milestone boss encounters:
  - start the first boss encounter after 5 minutes of regular encounter time;
  - schedule the next boss after another 5 minutes of regular encounter time following the previous boss defeat, so bosses can never overlap;
  - suspend the normal encounter budget during a boss and allow only the boss-specific adds declared by its data resource;
  - change movement and attack patterns at 66% and 33% health;
  - resume regular encounters after an 8-second recovery window;
  - select eligible bosses with the run seed and prevent the same boss from appearing twice in succession.
- Ship Phase 2 with one complete Command Carrier boss based on the mother-ship family, including a dedicated boss health bar, aimed volleys, drone reinforcements, and two phase transitions. Additional bosses must be addable through data without changing the director.
- Replace the wave HUD with survival time and current danger.
- Add `bestTime` to solo and co-op save records without converting or deleting legacy `bestWave` values.
- Reassign F1/F2 to decrease/increase the debug danger offset while preserving F3–F6.

Validation:

- The same seed and event sequence produce identical encounters and spawn positions.
- A different seed produces a different encounter sequence.
- Encounter transitions never interrupt the run.
- Stronger enemy families become measurably more frequent as danger rises while common enemies remain present.
- Elite promotion follows the configured curve, respects active caps, and is visually unmistakable in both graphics modes.
- The first boss starts after five minutes of regular encounters, normal spawning is suspended, and no boss overlap is possible.
- Boss phase changes occur once at the configured health thresholds and the director resumes after the recovery window.
- Existing save files load without losing scores.

Planned commits:

- `feat(waves): add threat-budgeted encounter director`
- `feat(enemies): add deterministic elite variants`
- `feat(waves): add milestone boss encounters`
- `feat(ui): track survival time danger and bosses`

## Phase 3 — Add experience orbs and run levels

- Replace direct power-up drops with falling experience orbs that can be attracted by a player's pickup field.
- Pool orbs and defer collision disabling and reparenting so collection remains safe during physics callbacks.
- Start with these drop bands:
  - common enemies: 30–45% chance, 1 XP;
  - specialists: 60–75% chance, 2–4 XP;
  - heavy enemies: 100% chance, 6 XP.
- Share experience in co-op regardless of which player collects the orb.
- Calculate the next threshold with `round(10 * 1.28^(level - 1))` and carry excess XP forward.
- Target the first choice at 20–25 seconds and subsequent early choices every 35–50 seconds.
- Fully pause gameplay while upgrade choices are open.
- Present three distinct personal offers to each living player.
- In co-op, resume only after both living players confirm a choice.
- Queue multiple level-ups and resolve them in order.
- Add these ranked upgrades:
  - speed: +30, 4 ranks, total speed capped at 480;
  - damage: +0.25, 5 ranks;
  - fire rate: -0.02 seconds, 5 ranks, minimum delay 0.12 seconds;
  - side shots: unlock, then +0.2 damage, 4 ranks;
  - beam charge: -12%, 4 ranks;
  - orb attraction: +48 pixels, 4 ranks;
  - repair: +2 energy when applicable;
  - shield: +1 charge, capped at 3;
  - salvage: +500 score.
- Remove capped upgrades from the offer pool. If no valid offer remains, grant salvage automatically.

Validation:

- Offers are distinct, valid, and reproducible for a fixed seed.
- Excess XP and queued level-ups resolve correctly.
- Each co-op player uses their configured controller independently.
- No legacy direct power-up can spawn.
- Orb collection never removes a collision object during a physics callback.

Planned commits:

- `feat(progression): add pooled experience orbs`
- `feat(progression): add ranked level-up choices`
- `feat(ui): add cooperative level-up selection`

## Phase 4 — Improve movement and add enemy roles

- Add movement-profile resources with stable identifiers for straight, sine, zigzag, patrol, dive, and controlled-exit motion.
- Improve existing enemies:
  - asteroids gain seeded drift and rotation;
  - drones use sinusoidal formations;
  - TIE fighters turn smoothly instead of reversing abruptly;
  - interceptors use diagonal strafing paths;
  - heavy units patrol laterally within bounds.
- Add three enemies with dedicated pixel-art sprite sheets:
  - dive hunter: telegraphs and then charges the player's last known position;
  - bomber: follows a wide zigzag and drops slow projectiles;
  - sniper: strafes, telegraphs an aimed shot, fires, and retreats.
- Build every new ship from an original silhouette and the approved faction design language. Distinguish roles through this project's own shapes, palettes, propulsion, weapon, and animation rules.
- In co-op, target the closest living player and break equal-distance ties deterministically by player identifier.
- Add the new roles to progressively higher danger ranges, with all roles available before eight minutes.

Validation:

- Movement paths remain reproducible for a fixed seed.
- Every dangerous attack has a visible telegraph.
- Enemies cannot remain stuck outside the playfield.
- Each new enemy has a distinct tactical role.

Planned commits:

- `feat(enemies): add configurable movement profiles`
- `feat(enemies): add hunter bomber and sniper archetypes`

## Phase 5 — Improve particles and bonus shaders

- Add impact sparks, colored explosion bursts, orb trails, collection bursts, and a level-up ring.
- Strengthen feedback for every beam charge tier and make full charge unambiguous.
- Add two GL Compatibility-safe `CanvasItem` shaders:
  - a pulsing halo for experience orbs;
  - an outline and pulse for selected upgrade cards.
- Reduce particle counts and disable expensive variants in low graphics mode.
- Preserve the current 8-bit/Pico-8-inspired visual language and reuse existing sounds during this phase.

Validation:

- Shaders compile without errors under GL Compatibility.
- Bonuses remain recognizable in high and low graphics modes.
- Effects and helper nodes do not accumulate without bounds.

Planned commit:

- `feat(vfx): improve combat feedback and bonus shaders`

## Phase 6 — Balance and validate the complete run

- Add a headless simulation covering encounters, formations, elite promotion, boss scheduling and phases, drops, and upgrade offers.
- Compare two runs with the same seed against one run with a different seed.
- Profile solo and co-op simulations through 12 minutes, including at least one full boss cycle.
- Tune data resources to reach:
  - first level at 20–25 seconds;
  - subsequent early levels every 35–50 seconds;
  - the full encounter variety at 5–8 minutes;
  - strong pressure at 10–12 minutes.
- Test enemy and elite caps, boss non-overlap, queued levels, one-player death in co-op, and legacy save loading.
- Run Godot headless validation, followed by a manual 12-minute run in both modes.
- Update architecture documentation and debug-control documentation.

Planned commits:

- `test(gameplay): add deterministic run coverage`
- `chore(balance): tune endless run progression`
- `docs: document dynamic gameplay systems`

## Main interfaces

- Extend `UpgradeDefinition` with display name, description, icon, maximum rank, and repeatable status.
- Keep stable identifiers independent from display text and file paths for upgrades, enemies, encounters, and movement profiles.
- Add `BEAM_CHARGE`, `ORB_MAGNET`, and `SCORE` upgrade effects.
- Track ranks, caps, the beam charge multiplier, and attraction radius in `PlayerLoadout`.
- Add enemy spawn data for threat cost, danger range, selection-weight curve, elite eligibility, and elite modifiers.
- Add boss data for stable identifier, scene, danger eligibility, selection weight, phase thresholds, attack phases, and allowed reinforcements.
- Add `xp_value`, `xp_drop_chance`, `movement_profile`, and `rng_seed` to enemies.
- Add event-bus signals for enemy defeat, elite spawn, boss start, boss health, boss defeat, XP collection, run progression, time/danger updates, and upgrade selection.
- Keep `powerup_collected` as the notification for a confirmed upgrade choice.

## Future roadmap — Meta-progression

Create a separate `docs/meta_progression_plan.md` before implementing any permanent progression. That planning effort must decide:

- permanent currency earned from run results;
- unlockable ships with distinct base stats, starting weapons, and passive abilities;
- permanent upgrades and profile levels;
- unlock conditions based on objectives, survival time, defeated enemies, or achievements;
- hangar and progression-tree interfaces;
- strict separation between permanent progression and temporary run builds;
- `ShipDefinition`, `MetaUpgradeDefinition`, and `UnlockCondition` resources;
- save schema versioning, migration, reset, and corruption recovery;
- balance limits that prevent permanent bonuses from trivializing the early run;
- co-op ownership rules for currency and unlocks.

Do not add any of these systems, screens, currencies, or save fields during preparation phases A–B or gameplay phases 1–6. Stable identifiers introduced by the gameplay rework are the only current preparation for this future roadmap.

## Assumptions

- The existing repository and itch.io project remain the continuity of this game; the rework is not a greenfield sequel.
- `The Lost Jedi` is a legacy working label only until an original release title is approved.
- The next public itch.io build is the coordinated rebrand update produced after preparation phases A and B; development builds may remain private before that gate.
- Upgrade progression resets at the start of every run.
- Phase 2 includes one Command Carrier boss; further boss archetypes, rarity tiers, and weapon evolutions are outside this roadmap.
- The seed remains internal and is logged only while `global.Debug` is enabled.
- A run continues until every player is dead.
- Legacy scores and `bestWave` values remain in save files.
- The pre-existing local modification to `scenes/main/main.tscn` must remain outside all roadmap commits.
