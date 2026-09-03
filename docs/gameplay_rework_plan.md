# Dynamic Gameplay Rework Plan

## Summary

Evolve the existing game on `codex/dynamic-gameplay-rework` through two preparation phases, one visual production phase, and six independently verifiable gameplay phases. Keep the current repository and the existing itch.io project so the game-jam history, audience, and working code are preserved. A separate replacement repository is not required. Every phase must leave the game playable before the next phase starts.

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
- Phase 1: implementation completed on 2026-08-28; solo and co-op readability playtests remain before approval.
- Phase 1 follow-up — Wave variety preview: implementation completed on 2026-08-29; solo and co-op readability playtests remain before approval.
- Phase 1 follow-up — Difficulty and elite preview: implementation completed on 2026-08-29; solo and co-op difficulty playtests remain before approval.
- Phase 1 follow-up — Ranked direct power-ups and beam progression: implementation completed on 2026-08-29; balance playtests remain before approval.
- Phase 1 follow-up — Progression and readability balance: implementation completed on 2026-08-31; solo and co-op balance playtests remain before approval.
- Phase 1 follow-up — Weapon movement commitment: implementation completed on 2026-08-31; gameplay feel playtests remain before approval.
- Phase 1 follow-up — Configurable wave duration: implementation completed on 2026-08-31; pacing playtests remain before approval.
- Phase 1 follow-up — Plasma reserve beam: implementation completed on 2026-09-01; gameplay feel playtests remain before approval.
- Phase 1 follow-up — Speed and impact feedback: implementation completed on 2026-09-03; automated checks and visual capture pass, while solo and co-op gameplay feel playtests remain.
- Visual production phase: planned and approved on 2026-08-29; implementation starts only after Phase 1 approval.
- Next implementation step: playtest the speed and impact feedback with the plasma reserve beam on waves 1–3, 6, and 9 in solo and co-op before approving Phase 1.

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

Status: implemented on 2026-08-28. Automated checks and a headless startup smoke test pass. The approved Phase B background base speed remains at 60 logical pixels per second because it is purely visual and its readability constraint supersedes the earlier 140-to-168 target. The maintainer later requested a subtle 1.1 multiplier for the nearest parallax layer while retaining the middle and far layer speeds. Solo and co-op readability playtests remain before this phase can be approved.

- Increase player base speed from 300 to 360 and use a maintainer-adjusted base fire delay of 0.18 seconds. Keep the Phase B visual background at 60 logical pixels per second instead of the superseded 140-to-168 target.
- Increase primary, side-cannon, and plasma-beam projectile travel speeds by 20% as requested by the maintainer.
- Increase base enemy travel speeds by roughly 20% and enemy projectile speed by 10% to preserve readability.
- Remove the original heavy movement penalty while charging the beam; a later follow-up applies a lighter tactical slowdown to both weapon inputs.
- Keep the short movement penalty caused by taking damage.
- Stop resetting the loadout when a player takes damage.
- Keep run upgrades until the run ends.
- Add a focused combat-feedback pass with player-weapon recoil, damage flashes, and proportional camera shake for player hits, plasma-beam fire, and enemy destruction. Keep the broader particle and shader work in Phase 5.
- Add a temporary tiered score combo multiplier with one cumulative floating score popup to reward sustained aggression without cluttering dense encounters.
- Make every plasma-beam tier pierce enemies, let a fully charged beam span the visible playfield and follow the player briefly, and favor meaningful offensive power-ups in the temporary direct-pickup system.

Validation:

- Player weapon use retains 88% of the current loadout speed before the temporary hit penalty.
- Player projectiles travel 20% faster without changing their damage.
- Taking damage does not remove any upgrade.
- Movement, shooting, and collisions remain readable in solo and co-op.
- Combat feedback never moves collision shapes or the HUD.

Planned commits:

- `feat(player): increase gameplay pace`
- `fix(player): preserve beam mobility and upgrades`

## Phase 1 follow-up — Dedicated weapon inputs

Status: implemented on 2026-08-30. This control pass separates sustained primary fire from plasma-beam charging and slightly shortens its charge cadence for the dedicated input.

- Keep primary fire on Space, Insert, keypad `+`, and A/Cross. Fire immediately and continue at the loadout's current fire delay while held.
- Charge the plasma beam independently with left Shift or B/Circle, then release it at the highest reached tier.
- Give plasma-beam charging priority when both actions are held. A successful beam release suppresses primary fire for that frame, then sustained fire may resume.
- Clear both actions and cancel pending charge state across pause, restart, screen changes, and controller refreshes.
- Shorten the small, normal, and full beam thresholds from 0.50/1.20/2.40 seconds to 0.45/1.05/2.10 seconds. Preserve rank gates, damage, recoil, and visual offsets.
- Start the beam charge particles after 0.10 seconds so every valid charge has an immediate visual response.

Validation:

- Sustained primary fire follows the configured timer and stops on release.
- Beam charge never emits primary shots and never shares its release frame with a primary salvo.
- Releasing before the first beam tier resumes held primary fire without emitting a beam.
- Solo, keyboard co-op, and both gamepad device mappings remain independent after pausing or changing screens.

Commit:

- `feat(player): separate primary fire and beam controls`

## Phase 1 follow-up — Add weapon movement commitment

Status: implemented on 2026-08-31. This control refinement makes firing positions more deliberate without restoring the original heavy beam movement penalty.

- Expose one shared `weapon_speed_multiplier` in the player stats resource and set it to 0.88 for both primary fire and beam charge.
- Keep beam firing priority when both weapon inputs are active; the shared movement multiplier remains unchanged.
- Restore full movement speed immediately when the relevant input is released. Apply the existing temporary hit penalty after the weapon multiplier.
- Resolve the slowdown from each player's mapped actions so solo, keyboard co-op, and both gamepads remain independent.

Validation:

- Movement uses 100% of the current loadout speed while idle and 88% while firing or charging.
- Holding both weapon inputs retains the shared 88% multiplier, and releasing every weapon immediately restores full speed.
- One player's weapon input never slows the co-op partner.

## Phase 1 follow-up — Replace beam charging with a plasma reserve

Status: implemented on 2026-09-01. Automated gameplay, balance, and visual checks pass; maintainer gameplay feel playtests remain required before starting another feature phase.

- Replace the tiered hold-and-release beam with a central continuous beam that drains a personal plasma reserve while its dedicated input is held.
- Start each player at 0 plasma, require 10 to activate, cap the reserve at 100, and drain 20 per second. Releasing the input preserves the remaining reserve.
- Suppress primary fire only while the beam is active and retain the shared 0.88 weapon movement multiplier.
- Let a full reserve trigger a one-second overdrive with increased width and damage. The beam remains purely offensive and never destroys enemy projectiles.
- Remove beam ranks and make the standard damage upgrade affect the continuous beam alongside the other player weapons.
- Add frequent plasma-cell drops through one exclusive reward roll per normal enemy. Keep direct power-ups rarer within the overall reward stream until Phase 3 removes them.
- Share every collected plasma cell with both living co-op players while keeping their reserves and activation inputs independent.
- Keep plasma cells as an immediate-combat resource distinct from the shared experience introduced in Phase 3.

Validation:

- Partial activations, release conservation, empty-reserve shutdown, full-reserve overdrive, pause cleanup, and co-op input independence behave consistently.
- The beam ticks every 0.1 seconds across every overlapping enemy without repeated impact recoil or collision changes during a physics callback.
- Normal enemies drop at most one reward, elites guarantee one power-up plus a large plasma cell, and collection safely disables its collision.
- Seeded balance simulation targets one full reserve every 35 to 50 seconds without exceeding 20% sustained beam uptime over five minutes.
- Solo and co-op playtests confirm that partial activations solve emergencies, overdrive is worth saving, and the primary cannon remains the dominant weapon.

## Phase 1 follow-up — Strengthen speed and impact feedback

Status: implemented on 2026-09-03. Automated checks and a GL Compatibility visual capture pass; solo and co-op gameplay feel playtests remain. This focused visual pass precedes the broader explosions, trails, and shaders retained for Phase 5.

- Add a bounded foreground `GPUParticles2D` layer of downward light streaks over the playfield and below the HUD.
- Smoothly adapt streak speed to the average vertical movement intent in solo and co-op without changing gameplay speed or seeded state.
- Replace frame-random camera offsets with coherent noise, stronger player-hit feedback, proportional enemy-destruction feedback, and capped accumulation for simultaneous impacts.
- Keep all camera motion on `Camera2D.offset` so the HUD, collision shapes, and world nodes retain their authoritative positions.
- Remove the obsolete low/high graphics setting and retain one GL Compatibility-safe visual presentation.
- Preserve authored projectile sprites and animations while adding restrained lateral glows to player and enemy shots, plus layered beam luminance, without trails; broader projectile VFX remain in Phase 5.

Validation:

- Foreground particles remain bounded, non-interactive, and clear of the HUD hierarchy.
- Opposing co-op movement inputs average the streak speed without either player owning the effect.
- Player hits, player destruction, and enemy destruction produce distinct strengths; simultaneous impacts never exceed the configured cap.
- Existing saves keep audio, fullscreen, and controller preferences while discarding the removed graphics key on their next save.
- Solo and co-op playtests confirm that projectiles and collision cues remain readable during dense waves.

## Phase 1 follow-up — Preview more varied enemy waves

Status: implemented on 2026-08-29. Automated resource and formation checks pass, and a headless runtime smoke test completed one full wave and its transition without errors. Solo and co-op readability playtests remain before approval.

- Keep the fixed 13-wave catalog as an intermediate gameplay preview rather than starting the seeded director from Phase 2.
- Keep a 24-second authored baseline split into a 6-second opening, a 2-second pause, a 6-second buildup, a 2-second pause, a 6-second climax, and a final 2-second transition window. A later follow-up scales this timeline to the configured runtime duration.
- Recompose the catalog with the existing asteroid, drone, fighter, interceptor, turret, and carrier scenes. Do not introduce new enemies, artwork, combat statistics, elites, or bosses in this follow-up.
- Add reusable single, line, V, alternating-edge, scatter, and offset-group formations. Keep every formation on unique valid lanes and reduce its size when the configured lane range cannot fit it.
- Run each spawn rule on an independent timeline and cancel stale timelines with a wave-generation token when the wave changes or the debug controls skip forward or backward.
- Keep existing enemies alive across wave transitions and cap active enemies and hazards at 45 in solo and 60 in co-op.
- In co-op, add one enemy to formations of four or more and reduce the interval of smaller repeating formations by 10%. Keep the existing enemy health multiplier unchanged.
- Preserve the unused encounter weight field for Phase 2 without assigning procedural selection behavior to it yet.
- Keep the final catalog entry looping until the run ends.

Validation:

- Every wave resource loads with a 24-second authored baseline, valid scenes, three scheduled acts, and the intended number of rules.
- Every formation uses unique lanes within the configured range, including narrow edge ranges and oversized formations.
- F1/F2 wave changes stop every pending spawn from the previous wave.
- Solo and co-op runs respect their active-enemy caps without clearing surviving enemies at an act or wave transition.
- Score, combos, power-ups, plasma beam, HUD, game-over flow, and legacy `bestWave` saves continue to work.

Commit:

- `feat(waves): diversify enemy wave encounters`

## Phase 1 follow-up — Make wave duration configurable

Status: implemented on 2026-08-31. This pacing adjustment lengthens the fixed catalog without creating an idle tail after the final act.

- Expose one `wave_duration` value in the shared spawner configuration and set the current runtime duration to 28 seconds.
- Keep each wave resource at its 24-second authored baseline and derive one runtime scale from `wave_duration / authored duration`.
- Apply that scale to act start delays, active durations, formation intervals, and gaps while preserving difficulty and endless pace multipliers.
- Use the configured duration for the master transition timer so debug wave changes continue to invalidate every pending timeline.

Validation:

- Every runtime wave lasts 28 seconds with the current configuration and every authored timing uses the same `28 / 24` scale.
- Changing the shared duration requires no edit to the thirteen wave resources.
- The number of scheduled formation cycles remains approximately stable instead of adding an empty transition tail or extra enemy density.

## Phase 1 follow-up — Difficulty and elite preview

Status: implemented on 2026-08-29. This controlled balancing pass keeps the fixed catalog and direct pickups while testing wave scaling and scheduled elites before the seeded encounter director from Phase 2.

- Preserve the first three waves, then use existing wave difficulty values to scale combat enemy health and spawn cadence through wave 13. Asteroids remain unscaled hazards.
- Loop waves 9 through 13 after the first full catalog pass. Each loop increases enemy health by 10%, up to 50%, and reduces spawn intervals by 5%, up to 20%.
- Add durability categories for fodder, fighters, specialists, and heavy ships with distinct maximum health multipliers. Keep co-op pressure density-based instead of adding a health multiplier.
- Add exactly one scheduled elite in the climax of waves 6, 9, 12, and 13. Elites use 1.5x health, 1.1x speed, 0.8x shooting delays, triple score, a guaranteed power-up drop, a pale-violet treatment, pulsing red aura, and compact health bar.
- Keep the collision shape unchanged and cap active elites at three. Do not add seeded promotion, threat budgets, XP rewards, boss scheduling, or future enemy roles in this preview.

Validation:

- Wave health and cadence scale only after difficulty 1.30, and asteroids never gain health.
- The 13 → 9 loop increments exactly once per completed advanced cycle and respects its health and pace caps.
- Scheduled elites appear only at their declared climax rules, never exceed one per formation or three active instances, award triple score, and guarantee one power-up drop when destroyed by a player.
- Solo and co-op runs remain readable with no bonuses early and meaningful pressure after multiple offensive upgrades.

## Phase 1 follow-up — Ranked direct power-ups and beam progression

Status: implemented on 2026-08-29. This balancing follow-up keeps direct pickups temporarily while making their progression explicit before the Phase 3 XP-choice system replaces them.

- Give speed, damage, fire rate, side shots, and plasma beam fixed visible ranks with explicit caps. Keep shield and energy as consumables.
- Keep the plasma beam deliberately gated: the basic rank can only release its smallest bolt, rank 3 unlocks the normal charge, and rank 8 unlocks the full-screen charge.
- Separate speed from firing cadence, add dedicated fire-rate and beam pickups, and use relative pickup weights instead of cumulative thresholds.
- Spread the same final stat ceilings across 7 or 8 ranks and reduce power-up drop chances, so a fully built ship remains a late-run achievement.
- Make every beam rank improve charge time, beam damage, full-beam duration, and width while retaining the screen-spanning follow behavior.
- Convert a permanent pickup collected after its cap into 500 direct score points without affecting the combo or the co-op partner.
- Display each player's permanent ranks and short upgrade feedback in the HUD. Reuse the current pickup art and audio with distinct tints until the visual production phase.
- Raise the mother ship's base health from 30 to 40 while retaining its heavy-ship, elite, wave, cycle, and co-op scaling.

Validation:

- Every permanent upgrade stops exactly at its visible rank cap, including after pooled projectile reuse.
- Fire rate reaches 0.13 seconds only through its dedicated pickup, and speed reaches 450 without changing it.
- Solo and co-op HUDs display independent player ranks, capped pickup feedback, and the 500-point conversion.
- Beam charge thresholds, damage, full duration, and width increase across all five ranks without regressing its pierce or follow behavior.
- Mother ship health scales from the new 40-health base through the advanced-wave and endless-loop rules.

## Phase 1 follow-up — Balance progression and late-wave readability

Status: implemented on 2026-08-31. This pass accounts for the sustained primary-fire input by increasing early shot breakpoints, slowing temporary direct-pickup growth, and separating late pattern families without starting the Phase 2 director.

- Raise drones and fighters to 2 base health, interceptors to 6, and lower standalone turrets to 30. Keep hazards, the 40-health mothership, and its 10-health modules unchanged.
- Cap first-cycle durability scaling at 1.15x for fodder, 1.25x for fighters, and 1.30x for specialists and heavy enemies. Cap endless health growth at 1.35x and retain the actual 1.50x elite multiplier.
- Set exact direct-pickup chances to 2% for asteroids, 4% for large asteroids, 6% for drones, 25% for interceptors, 30% for standalone turrets, and 35% for motherships. Fighters and mounted modules never drop one, while every elite guarantees one.
- Reduce damage and beam gains to 0.15 per rank, side-cannon gains to 0.08 after unlock, and fire-delay gains to 0.00625 seconds with a 0.13-second minimum. Preserve rank counts, pickup weights, speed, energy, shield, and beam thresholds.
- Recompose waves 9 through 13 so each six-second act introduces at most one of the mothership, standalone turret, or interceptor pattern families. Use drones, fighters, and asteroids as support and preserve one scheduled elite in waves 6, 9, 12, and 13.
- Keep every projectile produced by a pattern; readability is authored through encounter composition rather than a runtime projectile cap.

Validation:

- Base drones and fighters take two primary impacts and reach three health by wave 13; the endless and durability multipliers respect their new caps.
- A seeded 10,000-run simulation averages two to four direct pickups through wave 3 and seven to ten through wave 5.
- Maximum primary damage is 2.20, each side cannon reaches 0.88, the beam-specific bonus reaches 1.20, and sustained cannon DPS remains near 30.5.
- Waves 9 through 13 introduce no conflicting major pattern families within one act and retain their intended elite schedule.
- Solo and co-op playtests cover waves 1 through 3 and 9 through 13 before Phase 1 approval.

## Phase 1 follow-up — Give turrets and mother ships distinct combat identities

Status: implemented on 2026-08-30. Automated scene loading and the dedicated headless enemy-identity harness pass. Solo and co-op readability playtests in waves 9, 12, and 13 remain before approval.

- Keep drones as simple fodder, fighters as mobile pressure, and interceptors as spread-fire specialists. Limit this follow-up to turrets and mother ships.
- Replace the turret's random lateral shot with a telegraphed deterministic cycle: a three-shot aimed burst, a short pause, a ten-shot radial ring, and an alternating angular offset on successive rings.
- Lock aimed volleys to the nearest living player at telegraph time. Let each turret choose independently in local co-op.
- Slow standalone turrets to 80 logical pixels per second and begin their attack cycle only after they enter the visible playfield.
- Teleport each mother ship to the first available upper-playfield anchor in center, left, right order. Keep it stationary and discard a fourth concurrent mother ship without reward.
- Disable the mother ship and its mounted turrets during the 0.65-second arrival telegraph and materialization sequence.
- Give each mother ship two independently destructible mounted turrets with 10 base health, normal run health scaling, 250 score, and no power-up drop. Stagger their attack cycles.
- Keep the hull dangerous after both turrets are destroyed with a five-shot slow fan every 2.4 seconds.
- Stop and disable every mounted turret before the hull explosion, without freeing a collision object during the physics callback.
- Extend pooled enemy shots with full two-axis velocity while retaining the legacy horizontal-speed helper for existing enemies.

Validation:

- The first three concurrent mother ships occupy center, left, and right anchors without overlap; a fourth leaves the active-enemy tracker cleanly.
- No hull, module collision, or projectile becomes active before materialization completes.
- A turret fires exactly three aimed projectiles at `-5`, `0`, and `+5` degrees, then ten evenly distributed radial projectiles; successive rings differ by 18 degrees.
- Destroying a mounted turret stops only that module, while destroying the hull immediately disables both modules.
- Pooled turret projectiles reset their velocity before reuse.
- Turret and mother-ship scenes run safely in isolation without a player target.

Planned commit:

- `feat(enemies): distinguish turret and mother ship combat`

## Visual production phase — Rebuild the core sprite set

Status: planned and approved on 2026-08-29. Implement this phase after Phase 1 is approved and before Phase 2 begins.

- Define one production specification from the approved universe bible and 24-color palette: pixel grid, maximum sprite dimensions, frame layout, pivots, animation timing, outline rules, faction materials, engine colors, and projectile readability.
- Replace the retained player set with original Lost Warden art:
  - Nomad fighter sprites for both players;
  - reactor particles and gameplay energy icons;
  - energy shield, pulse-cannon shots, side-cannon shots, and plasma beam.
- Replace every retained current enemy and hazard sprite with original silhouettes from the approved faction language:
  - Razor Fighter, Talon Interceptor, Siege Turret, Razor Wing drone, and Grave Carrier;
  - small and large asteroids;
  - all corresponding enemy projectiles.
- Replace the retained space backgrounds and star textures while preserving the existing parallax behavior and gameplay readability.
- Preserve scene paths, stable gameplay identifiers, pivots, animation names, and collision shapes unless an atomic compatibility migration is explicitly required.
- Keep editable source files synchronized with exported runtime PNG files. Do not commit a runtime sprite without its corresponding source when one is used.
- Do not redraw the legacy direct power-up because Phase 3 removes it.
- Produce phase-specific future art in the phase that owns its mechanics:
  - elite variants and the Dread Ark in Phase 2;
  - Energy Shards and upgrade icons in Phase 3;
  - hunter, bomber, and sniper sprite sheets in Phase 4;
  - explosions, particles, and combat effects in Phase 5.
- Keep this phase visual-only. Do not change damage, movement, collision sizes, encounter data, or other gameplay behavior while replacing sprites.

Validation:

- No retained runtime ship, enemy, hazard, projectile, shield, or background uses a legacy-franchise silhouette or unapproved palette.
- Player, enemy-family, projectile, and hazard silhouettes remain readable at gameplay scale in solo and co-op.
- Every animation keeps its expected frame count, pivot, node path, and callback behavior.
- Collision shapes remain aligned without being resized to match decorative effects.
- The single visual presentation remains legible under the GL Compatibility renderer.
- Title, gameplay, pause, game-over, solo, co-op, browser fullscreen, and responsive Web flows load without missing resources or distorted sprites.
- Updated gameplay screenshots are captured only after this phase passes validation.

Planned commits:

- `feat(art): replace player and weapon sprites`
- `feat(art): replace enemy and hazard sprites`
- `feat(art): replace space backgrounds`

## Phase 2 — Add the seeded encounter director, elites, and bosses

- Turn the current waves into weighted encounters lasting 20 to 30 seconds and chain them without a gameplay break.
- Extend wave resources with a stable identifier, danger range, selection weight, threat budget, and formation data.
- Give every enemy family a threat cost, minimum danger, maximum danger, and weight curve. As danger rises, the director must spend a larger budget and progressively favor interceptors, turrets, mother ships, and later enemy families without removing common enemies completely.
- Add line, V, scatter, alternating-edge, and offset-group formations.
- Prevent either of the previous two encounters from repeating when another eligible encounter exists.
- Centralize encounter timers and remove obsolete timer nodes and signal connections from the world scene.
- Generate one internal seed per run and derive four independent random streams for encounters, enemy initialization, orb drops, and upgrade offers.
- Keep cosmetic randomness separate so visual feedback cannot alter seeded gameplay.
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
- Elite promotion follows the configured curve, respects active caps, and is visually unmistakable in the supported presentation.
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
- Strengthen feedback for the continuous plasma beam and make full-reserve overdrive unambiguous.
- Add two GL Compatibility-safe `CanvasItem` shaders:
  - a pulsing halo for experience orbs;
  - an outline and pulse for selected upgrade cards.
- Keep particle counts bounded and compatible with the GL Compatibility renderer.
- Preserve the current 8-bit/Pico-8-inspired visual language and reuse existing sounds during this phase.

Validation:

- Shaders compile without errors under GL Compatibility.
- Bonuses remain recognizable in the supported presentation.
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
- Run Godot headless validation, followed by manual 12-minute solo and co-op runs.
- Update architecture documentation and debug-control documentation.

Planned commits:

- `test(gameplay): add deterministic run coverage`
- `chore(balance): tune endless run progression`
- `docs: document dynamic gameplay systems`

## Main interfaces

- Extend `UpgradeDefinition` with display name, description, icon, maximum rank, and repeatable status.
- Keep stable identifiers independent from display text and file paths for upgrades, enemies, encounters, and movement profiles.
- Add `ORB_MAGNET` and `SCORE` upgrade effects.
- Track ranks, caps, and attraction radius in `PlayerLoadout`; plasma reserve remains player combat state rather than an upgrade rank.
- Add enemy spawn data for threat cost, danger range, selection-weight curve, elite eligibility, and elite modifiers.
- Add boss data for stable identifier, scene, danger eligibility, selection weight, phase thresholds, attack phases, and allowed reinforcements.
- Add `xp_value`, `xp_drop_chance`, `movement_profile`, and `rng_seed` to enemies.
- Add event-bus signals for enemy defeat, elite spawn, boss start, boss health, boss defeat, XP collection, run progression, time/danger updates, and upgrade selection.
- Keep `plasma_collected` and `beam_charge_changed` separate from XP events so immediate combat energy never changes run-level progression.
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

Do not add any of these systems, screens, currencies, or save fields during preparation phases A–B, the visual production phase, or gameplay phases 1–6. Stable identifiers introduced by the gameplay rework are the only current preparation for this future roadmap.

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
