# Legacy reference art cleanup — 2026-10

Removed legacy reference-only images from `assets/art/`, along with their corresponding Godot `.import` metadata, after checking existing repository references and the prior [rebrand migration inventory](rebrand_migration_inventory.md).

- Atari: `atari_2600.jpg`, `atari_2600_01.png`, `atari_7800.png`, `atari_logo.jpg`.
- Star Wars: `death_star.jpg`, `tie_fighter.jpg`, `tie_fighter_rebels.jpg`, `x_wing_swb.jpg`, `x_wing_swb.png`.

**Not removed:** in-game enemy/player assets and scripts (e.g. `tie_sheet.png`, `tie_explode.wav`, `tie_shoot.wav`, `tie.tscn`, `x_wing.png`) because current Godot scenes still refer to them. They need an independent rebrand/replacement migration before deletion.

Removal from the current tree does not remove files from Git history or revoke any license previously granted. Validate the Godot project import and playthrough before merging.
