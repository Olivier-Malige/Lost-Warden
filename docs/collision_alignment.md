# Collision alignment

Collision dimensions use sprite-local pixels. Shared parent transforms affect the
sprite and collision together; collision nodes themselves keep unit scale.

- Player: a stable 16 × 16 rectangle centered at (0, -2), inside the neutral
  silhouette. Banking does not change the vulnerable area; wing tips are forgiving.
- Enemies: rectangles inset two pixels from the visible body bounds. These are
  simple body approximations, not per-pixel outlines.
- Asteroids: local circles of radius 10 and 13, covering the central body across
  rotations. The large asteroid root uses an intentional integer 2× scale, so its
  visible body is about 64 pixels wide and its world-space collision radius is 26.
  Small asteroids stay at 1× (about 26 pixels wide), including detached fragments.
  Large asteroid centers stay between x = 140 and 500 to keep their rotating
  silhouettes out of the HUD rails.
- Pickups: 14 × 14 rectangles inside the 16 × 16 icons.
- Projectiles: rectangles centered on the opaque frame bounds. Player projectile
  animations update shape size and position for each tier and both teams. Shapes
  are local to each instance so changing one projectile cannot resize another.
- Shield: each tier follows the resting arc bounds. Impact flashes retain that
  tier's collision rather than enlarging it. An empty shield disables its shape
  and monitoring; collecting shield power restores both.
- Beam: collision spans from the emitter to the top edge and follows normal and
  overdrive widths, retaining the existing 1.2 contact-width multiplier.

Verification:

```sh
godot --headless --path . --script tests/player/test_collision_alignment.gd
godot --headless --path . --script tests/player/test_beam_effect.gd
godot --headless --path . --script tests/player/test_fire_input.gd
godot --headless --path . --script tests/test_native_scale.gd
```

The alignment check reads actual texture alpha bounds, checks enemy and pickup
animation frames excluding explosions, exercises both teams' projectile tiers,
checks independent projectile shapes, and verifies shield activation/depletion.
The beam check also validates collision length, placement, and width transitions.
