# Rebrand Migration Inventory

Status: approved; Preparation phase B completed on 2026-08-28
Legacy baseline: Git tag `alpha-7`  
Target identity: the light arcade space-opera direction defined in `docs/universe_bible.md`

This inventory separates reusable gameplay mechanics from legacy fictional identity. No listed rename or deletion is authorized until the universe bible is approved. Paths are recorded explicitly because scenes, animations, and player assets contain dynamic references.

## Disposition codes

- **Replace:** create an original equivalent, switch references, then remove the legacy item after validation.
- **Rename:** retain the underlying original work but change public terminology and, where safe, its path.
- **Retain:** keep the item because it is generic, original, licensed for reuse, or mechanically internal.
- **Remove:** delete only after a reference audit proves it is unused or its presentation role has ended.
- **Review:** establish authorship, license, or perceptual similarity before deciding.

Compatibility aliases are temporary and exist only when a dynamic path, save field, animation track, or cross-phase dependency makes an atomic rename unsafe.

## Release identity and public copy

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| `The-lost-jedi` / `THE-LOST-JEDI` | `project.godot`, `scenes/menu/start.tscn`, `export_presets.cfg`, legacy `export.cfg` | Approved final title and matching export slug | Replace | Keep repository URL unchanged until hosting and release links are coordinated | Preparation B |
| Repository heading and description | `README.md` | Describe the original universe while preserving the Game Off origin in history/credits | Replace | Keep the existing GitHub URL unless the repository itself is renamed separately | Preparation B |
| itch.io title and description | Existing itch.io project | Approved title, new premise, controls, Web notes, and legacy-edition link | Replace | Preserve the existing project/page continuity | Preparation B release |
| Store banner, cover, screenshots, thumbnails | itch.io project; current `assets/art/banner.png` where applicable | New key art and gameplay captures using the original identity | Replace | Retain old media only in the legacy release/archive | Preparation B release |
| Embedded itch.io/Godot marks | `assets/sources/ui/icon_itch.ase`, `assets/sources/ui/godot.ase` | Retain only where platform attribution is accurate; do not use as game identity | Review | Platform marks remain separate from the game emblem | Preparation B |
| Download and Web archive filenames | Current build/release workflow | Approved lowercase release slug | Rename | Legacy downloads keep their historical filenames | Preparation B release |
| Game-jam history and credits | `README.md`, loader copy, itch.io page | Concise factual credit with link to tagged legacy edition | Retain | None | Preparation B |
| `alpha-7` tag | Git | Preserve as the identifiable legacy/game-jam-compatible reference | Retain | Do not move or overwrite the tag | Preparation A |

## Presentation, title screen, and metadata

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| Television/computer casing | `assets/sprites/world/background_tv.png`, `assets/art/cpu.png`, `assets/art/cpu_v2.png`, `assets/art/tv_back.*`, `scenes/main/main.tscn` | Direct full-viewport presentation | Remove | None after scene references are removed | Preparation B |
| Border masks and camera zoom markers | `scenes/main/main.tscn`, `scenes/main/main.gd` | Responsive full-viewport bounds and transitions | Remove | Keep OS fullscreen preference independent | Preparation B |
| Decorative X-wing lights | `scenes/main/light_x_wing_red.tscn`, `scenes/main/main.tscn` | No outer decorative ship lights | Remove | None | Preparation B |
| Decorative TIE lights | `scenes/main/light_tie.tscn`, `scenes/main/main.tscn` | No outer decorative ship lights | Remove | None | Preparation B |
| Decorative Death Star light group | `scenes/main/main.tscn`, shared light textures/scripts | No outer decorative station lights | Remove | Retain shared generic light assets only if referenced elsewhere | Preparation B |
| Star Wars reference art | `assets/art/death_star.jpg`, `tie_fighter.jpg`, `tie_fighter_rebels.jpg`, `x_wing_swb.*` | New original key-art source or no replacement if unused | Remove | None | Preparation B cleanup |
| Atari presentation art | `assets/art/atari_2600*`, `atari_7800.png`, `atari_logo.jpg` | Original arcade presentation, if these assets are actually shown | Remove | None | Preparation B cleanup |
| Existing title font presentation | `assets/fonts/title.tres`, `vermin_vibes_1989.ttf`, `scenes/menu/start.tscn` | Approved readable pixel title treatment | Review | Keep font resource path until title layout is replaced | Preparation B |
| App icon | `assets/ui/icon.png`, `project.godot` | Original Warden or three-blade Dominion emblem selected during the art pass | Replace | Switch metadata and file together | Preparation B |
| Loader copy (`Arknoid present`, Game Off wording) | `scenes/main/main.tscn` | Brief studio credit plus accurate legacy-origin line, or move origin to credits | Replace | Preserve factual credits in README and store copy | Preparation B |
| Game Off loader art | `assets/art/game_off.png` | Keep only with the historical credit or legacy release, not as current key art | Review | Legacy build retains its original presentation | Preparation B |
| `Nub Version` label | `scenes/menu/start.tscn` | Semantic version/build label | Replace | None | Preparation B |
| Legacy export configuration | `export.cfg` | Remove if confirmed obsolete; otherwise update public title fields | Review | `export_presets.cfg` is the Godot 4 source of truth | Preparation B cleanup |

## Player ship and combat

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| X-wing player silhouette | `assets/sprites/player/x_wing.png`, `assets/sources/player/x_wing*.ase`, `scenes/player/player.tscn` | Nomad fighter sprite sheet and sources | Replace | Keep `player.tscn` and `Player` class; temporarily keep node name `xWing` because animation tracks and scripts target it | Preparation B |
| `xWing` node access | `scenes/player/player.gd`, `player_vitals.gd`, animation tracks in `player.tscn` | Eventually rename to `ShipSprite` in one coordinated scene/script change | Rename | Required temporary alias/node name until all tracks and calls move atomically | Preparation B |
| Player reactor particles | `assets/sprites/player/player1_particle.png`, `player2_particle.png`, reactor scenes | Nomad fighter cyan/violet engine blades | Replace | Filenames must stay synchronized with dynamic path construction in `player.gd` until code migration | Preparation B |
| Player life and energy UI | `assets/sources/player/player1_life.ase`, `assets/ui/player1_energy.png`, `player2_energy.png`, energy scenes | Nomad fighter icon and direct arcade energy gauge | Replace | Keep `player1_energy.tscn` / `player2_energy.tscn` until dynamic HUD path is deliberately migrated | Preparation B |
| Laser terminology and sprites | `assets/sources/player/laser*.ase`, `assets/sprites/player/player*_shot.png`, `player*_side_shot.png`, combat sprites | Pulse-cannon, plasma-beam, and side-cannon projectiles | Rename/Replace | Retain mechanical scene/class names such as `Shot`; migrate filenames only with preload references | Preparation B |
| Beam | `assets/sprites/player/beam.png`, `scenes/player/beam/`, weapon resources | Public name `Plasma Beam`; redraw only if current effect evokes legacy source material | Review | Retain internal `beam` identifiers for mechanical clarity | Phase 1 / Phase 5 |
| Shield | `assets/sprites/player/shield*.png`, `scenes/player/shield.*` | Original incomplete energy arc | Replace | Retain internal `shield` identifiers and upgrade ID | Preparation B |
| Generic player SFX | `assets/audio/sfx/player/*.wav` | New bright player-weapon signature where provenance or similarity is unclear | Review | Paths may remain until replacement files are ready | Preparation B |

## Enemies and hazards

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| TIE fighter | `scenes/enemies/tie.*`, `assets/sprites/enemies/tie_sheet.png`, `assets/sources/enemies/tie*.ase`, TIE SFX, wave resources | Razor Fighter (`razor_fighter`) | Replace/Rename | Keep `tie.tscn`, `tie.gd`, timer/callback names, and preload paths through Phase 2 unless migrated atomically with stable encounter IDs | Preparation B / Phase 2 data migration |
| Interceptor | `scenes/enemies/interceptor.*`, sprite/source/SFX and shot scenes | Talon Interceptor (`talon_interceptor`) | Replace/Rename | Existing generic identifier may remain internal temporarily; public display name changes first | Preparation B / Phase 4 movement |
| Turret | `scenes/enemies/turret.*`, sprite/source/SFX and shot scene | Siege Turret (`siege_turret`) | Replace/Rename | `turret` may remain as a mechanical compatibility identifier until movement profiles land | Preparation B / Phase 4 movement |
| Mother ship | `scenes/enemies/mother_ship.*`, sprite/source/SFX and shot scene, wave resources | Grave Carrier (`grave_carrier`) | Replace/Rename | Keep path aliases through Phase 2 boss/data work to avoid broad preload churn | Preparation B / Phase 2 data migration |
| Drone | `scenes/enemies/drone.tscn`, reactor particles and SFX | Small Razor Wing drone; consider the Brood only for genuinely new roles | Review | Keep stable generic `drone` identifier until encounter taxonomy is approved | Phase 2 / Phase 4 |
| Asteroids | `scenes/enemies/asteroid.tscn`, `big_asteroid.tscn`, sprites/sources/SFX | Updated original asteroids with seeded drift and rotation | Replace | Keep generic public name and internal `asteroid` paths/layer | Preparation B / Phase 4 movement |
| `tie_shot` and TIE audio names | `scenes/combat/tie_shot.tscn`, `assets/audio/sfx/enemies/tie_*` | Razor Fighter projectile assets and public terminology | Rename/Replace | Temporary filenames permitted while referenced by interceptor and wave content | Preparation B / Phase 2 data migration |
| Green laser and interceptor laser art | `assets/sprites/combat/*.png` | Dominion red/amber projectile language | Replace | Keep shot mechanics and collision behavior | Preparation B |
| Existing explosion sprites | enemy sprite/source files | Recolor/rework to player, Dominion, Brood, and Precursor palettes as applicable | Review | Generic explosion timing may be retained | Phase 5 |
| Existing enemy SFX | `assets/audio/sfx/enemies/*.wav` | Dominion mechanical signatures and generic asteroid impacts | Review | Reuse only after provenance and similarity review | Preparation B |

## World and gameplay UI

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| Current space backgrounds | `assets/sprites/world/background*.png`, `assets/sources/world/background.xcf`, `scenes/world/background.tscn` | Frontier Graveyard, Crimson Veil, Foundry, Dead Fleet, and Black Citadel visual language | Replace | Preserve scroll mechanics and resource paths until viewport work is complete | Preparation B |
| Generic star field | `scenes/main/star_field.gd`, `light_star.tscn`, shared light sprites | Direct-viewport space particles if still useful | Retain/Review | Must remain cosmetic and outside seeded gameplay RNG | Preparation B / Phase 5 |
| Wave counter and labels | `scenes/ui/hud.gd`, `world.tscn`, game-over screens | `SURVIVAL TIME` and `DANGER`; retain legacy best-wave save data invisibly | Replace | Keep `bestWave` save field; add `bestTime` without destructive migration | Phase 2 |
| Score | HUD, game-over and hi-score scenes | Keep the direct public label `SCORE` | Retain | Keep save field and scoring events | Phase 2 / Preparation B copy |
| Direct power-up pickup | `scenes/ui/power_up.*`, `assets/sprites/pickups/power_up.png`, pickup SFX | Energy shards and level-up choices | Replace | Keep `powerup_collected` event for confirmed choices as required by roadmap | Phase 3 |
| Upgrade names | `data/upgrades/*.tres`, current animations and HUD | Engine Boost, Weapon Power, Side Cannons, Energy Shield, Repair | Rename | Stable mechanical IDs remain unchanged; display names become separate data | Phase 3 |
| Hi-score, pause, and game-over layouts | `scenes/menu/*`, `scenes/ui/paused.*` | Direct arcade UI using approved Warden and Dominion visual accents | Replace | Preserve screen-flow events and focus behavior | Preparation B / Phase 2 |
| Game-over copy | `scenes/menu/game_over.tscn` | `GAME OVER`, survival time, danger reached, and score | Replace | Preserve legacy score and best-wave values in saves | Phase 2 |

## Audio and fonts

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| `imperial.ogg` / `imperial.mid` | start and game-over scenes; `assets/audio/music/` | Original heroic/dark military chiptune theme | Replace | Switch scene streams before removing files | Preparation B |
| `cantina.mmpz` | `assets/audio/music/` | Remove if source audit confirms it is unused; never ship in rebranded build | Remove | None | Preparation B cleanup |
| `game.ogg`, `loader.ogg` | gameplay/loader references | Original music with documented source project or replace | Review | Existing paths may remain during composition | Preparation B |
| `demo.wav` | `assets/audio/sfx/` | Remove if unreferenced | Remove | None | Preparation B cleanup |
| Generic SFX | `assets/audio/sfx/**` | Retain only if original/provenance-cleared and consistent with faction language | Review | Replace in place where that avoids scene churn | Preparation B |
| Current fonts | `assets/fonts/**` | Verify licenses; retain readable, redistributable fonts or replace with a licensed pixel family | Review | Theme resources provide temporary path compatibility | Preparation B |
| Legacy Godot 2 bitmap-font sources | `assets/fonts/_legacy_bmfont/` | Remove if Godot 4 resources do not depend on them | Review/Remove | Confirm references before deletion | Preparation B cleanup |
| Bus layout | root `default_bus_layout.tres`, `assets/audio/default_bus_layout.tres` | Keep required root layout; audit duplicate asset copy | Retain/Review | Root file must remain | Preparation B cleanup |

## Source files, documentation, and release archive

| Legacy reference | Location | Replacement or action | Disposition | Compatibility | Phase |
|---|---|---|---|---|---|
| Franchise-shaped Aseprite sources | `assets/sources/player/x_wing*.ase`, `assets/sources/enemies/tie*.ase` | New Nomad fighter and Razor Wing source sheets | Replace | Keep legacy files only in tagged history after runtime references switch | Preparation B |
| Generic editable sources | other `assets/sources/**/*.ase`, `.xcf` | Update or replace according to corresponding runtime asset | Review | Source and exported filename must remain synchronized | Each asset's phase |
| Architecture terms in README | `README.md` | Approved public terms plus stable internal-path notes where still necessary | Rename | Avoid lying about paths during temporary alias period | Preparation B and later docs |
| Roadmap legacy examples | `docs/gameplay_rework_plan.md` | Retain as historical implementation requirements | Retain | Do not rewrite approved roadmap terminology merely for presentation | All phases |
| Agent guide legacy project label | `AGENTS.md` heading and compatibility warnings | Retain until project title and dynamic paths are migrated; then update only public heading/examples | Review | Preserve technical warnings and current paths | Preparation B / relevant migration |
| Save records | `data.json`, `core/save_service.gd`, `core/global.gd` | Preserve score and `bestWave`; add `bestTime` in Phase 2 | Retain/Extend | No destructive conversion; no fictional display text in keys | Phase 2 |
| Legacy downloadable build | itch.io download linked to `alpha-7` | Clearly label as the original Game Off 2017 edition | Retain | Separate from the primary rebranded Web build | Preparation B release |

### itch.io legacy labels

Keep the historical uploads available with explicit display names:

- `The Lost Jedi — Legacy Alpha 6 (Windows)`;
- `The Lost Jedi — Legacy Alpha 6 (Linux)`;
- `The Lost Jedi — Legacy Alpha 6 (macOS)`;
- `The Lost Jedi — Legacy Web Build (pre-rebrand)` for the previous browser archive;
- `Lost Warden — Current Web Build` for the primary embedded release.

The legacy downloads remain historical artifacts and must not be presented as the recommended version.

## Mechanical reuse rules

The following systems are not identity-bearing and should be retained unless their roadmap phase requires a focused refactor:

- event-bus screen flow, HUD decoupling, and co-op ownership;
- collision layers and deferred physics/pooling safety;
- projectile pooling and shot damage mechanics;
- player input and controller assignment;
- weapon, upgrade, loadout, wave, and spawn resource patterns;
- save compatibility, score records, and fullscreen preference;
- debug mode and F1–F6 actions, with only the roadmap's planned reassignment;
- Pico-8-inspired low-resolution discipline, subject to original asset replacement.

Public display strings must not be used as stable identifiers. New enemy, encounter, boss, upgrade, and movement resources use explicit snake-case IDs. Legacy scene filenames may remain as compatibility paths until a focused migration is safer than a mass rename.

## Removal checklist

Before deleting any file listed as **Remove** or replaced asset:

1. Search text resources and scripts for its `res://` path and basename.
2. Check dynamic path construction in `player.gd` and `hud.gd`.
3. Open inherited scenes and animation tracks that may store node paths.
4. Reimport the project and run parser/resource validation.
5. Run the main scene through title, solo, co-op, pause, and game-over flows.
6. Build a local Web export and check the browser console for missing resources.
7. Keep the historical file available through Git tag `alpha-7`; do not copy it into the rebranded release archive.

## Approval record

Preparation phase A was approved before implementation began. The maintainer retained the arcade survival pitch, selected `Lost Warden` as the current public title, approved the Warden, Nomad fighter, Obsidian Dominion, enemy, boss, location, and optional faction directions, and confirmed the strict narrative limits and migration inventory.

Preparation phase B was approved on 2026-08-28 after the responsive Web build, direct viewport, interface redesign, palette, project icon, itch.io presentation, and release archive were reviewed. Gameplay screenshots remain deferred until the sprite rework is visible. Candidate music remains inactive pending a later audio review.
