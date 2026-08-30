# The-lost-jedi

8-bit shmup (8×8 sprites, Pico-8 palette) started at the OFFGame 2017 jam. Phaser prototype was dropped; the game was finished in Godot. Survive enemy waves, stack power-ups, chase high scores.

**Engine:** Godot **4.7** (GL Compatibility)  
**Main scene:** `res://scenes/main/main.tscn`  
**Source:** https://github.com/Arknoid/The-lost-jedi

## Run

1. Install [Godot 4.7](https://godotengine.org/download).
2. Import this repo (or open `project.godot`).
3. Press F5 — the main scene runs.

See [AGENTS.md](AGENTS.md) for layout, naming, and coding conventions.

## Structure

```
scenes/main/      entry, loader, star field, lights
scenes/world/     playfield, background
scenes/menu/      menu, start, game over, hi-score
scenes/player/    ship, shield, beam
scenes/enemies/   TIE, interceptor, turret, mother ship, asteroids
scenes/combat/    enemy shots, projectile pool
scenes/ui/        HUD, pause, power-ups
scenes/waves/     wave spawner
data/player/      player stats
data/weapons/     weapon definitions (.tres)
data/upgrades/    power-up definitions
data/waves/       catalog + wave definitions
core/             autoloads and save
assets/           sprites, audio, fonts, ui, art, sources
```

Scripts sit next to their scenes. Resource scripts (`class_name` + `.tres`) live in `data/`.

## Architecture

**Autoloads** (in `project.godot`):

| Name | Script |
|------|--------|
| `global` | `core/global.gd` — score, wave, config, save |
| `Events` | `core/events.gd` — event bus |

JSON save via `core/save_service.gd` (`user://data.json`).

**EventBus** (`Events`):

- `score_changed(score)`
- `wave_changed(wave)`
- `energy_changed(player_id, energy)`
- `player_died`
- `game_over_requested`
- `powerup_collected(upgrade)`

**Data-driven waves:** `data/waves/wave_catalog.tres` (`WaveDefinition` + `SpawnRule`). Runtime: `scenes/waves/wave_spawner.gd`.

**Weapons / upgrades:** `WeaponDefinition`, `UpgradeDefinition`, `UpgradeTable` in `data/`. Runtime loadout: `PlayerLoadout`.

**Player:** `player.gd` + `player_weapons.gd` + `player_vitals.gd` + `player_loadout.gd`.

**Projectiles:** pool in `scenes/combat/projectile_pool.gd`.

**Collision layers** (`project.godot`): `player`, `enemy`, `player_shot`, `enemy_shot`, `pickup`, `asteroid`.

**Debug:** enabled automatically in editor and debug builds, disabled in release exports. In game: F1/F2 previous/next wave; F3 speed; F4 damage; F5 side shot; F6 shield; F7 fire rate; F8 beam; F9 max stats, energy, and shield.

## Controls

Keyboard (AZERTY / QWERTY / arrows): Space (or keypad `+` / Insert) fires continuously; left Shift charges the plasma beam.

Gamepad: stick / D-pad; A/Cross fires continuously and B/Circle charges the plasma beam. Pause: Enter, R, or Start / L1.

In co-op, P1 is gamepad 0, P2 is keyboard (change in `global.saveData.config`).

## License

MIT. Copyright (c) 2017-2026 Arknoid / Olivier Malige. See [LICENSE.txt](LICENSE.txt).

## Credits

OFFGame jam 2017 — Max, Dicard, Mike (O’clock). Godot continuation: Arknoid / Olivier Malige.
