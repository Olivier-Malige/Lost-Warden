# Earlier, smaller Side Shots outer pair — 2026-10-28

The maintainer requested the two final-rank side shots earlier, at a smaller size, then explicitly selected rank two. Implemented locally as a scoped Phase 3 revision; no commit or publication requested.

## Current contract

| Rank | Side projectiles per volley | Inner damage per shot | Outer damage per shot | Outer native tier | Outer collision size |
| --- | ---: | ---: | ---: | --- | --- |
| 1 | 2 | 0.4 | — | — | — |
| 2 | 4 | 0.6 | 0.36 | Small | 2×3px |
| 3 | 4 | 0.8 | 0.48 | Medium | 4×4px |
| 4 | 4 | 1.0 | 0.60 | Full, existing final rank | 6×8px |

The primary cannon still adds one projectile per manual volley. The new count, outer damage fraction and secondary native visual tiers are authored in `data/upgrades/foundation/side_shot.tres`, validated by UpgradeDefinition and exposed in detached offers. PlayerLoadout derives its outer-pair flag from this resource. PlayerWeapons uses the same resource to emit the pair with an explicit native visual tier. Existing animation frames apply their matching local collision shape sizes/offsets without scaling Area2D or CollisionShape2D nodes.

Inner damage/visual progression remains unchanged. Outer damage remains 60% of the current inner projectile, receiving common DAMAGE once. The original inner ±51px/s and outer ±110.5px/s horizontal speeds, -540px/s vertical speed, firing cadence, owner identity, critical/explosion support and side-shot exclusion from lightning remain. Rank four retains its previous projectile count, size, damage and trajectories. No new art or icon style was introduced.

Cards distinguish two/four side shots and show inner damage, outer size and outer damage. The resource description explains the rank-two unlock and later growth.

## Verification

Godot 4.7.2, addon-free `.godot/phase_2_runtime_validation/` project and isolated APPDATA. Native rendering uses OpenGL Compatibility on the RTX 3060.

| Suite | Checks | Result |
| --- | ---: | --- |
| Earlier side pair, headless | 187 | Pass |
| Earlier side pair, native | 278 | Pass; stderr empty |
| Upgrade offers | 4,531 | Pass |
| Energy chains | 188 | Pass |
| Alpha 9 balance | 130 | Pass |
| Piercing and critical hits | 708 | Pass |
| Impact explosions | 203 | Pass |
| Upgrade selection | 76 | Pass |

Targeted checks cover every rank for both owners, exact volley counts, team frames, native collision sizes, unscaled nodes, per-shot damage snapshots, unchanged symmetric trajectories, actual outer-shot collision/damage/despawn, and reuse of full-size P1 shots as small P2 shots. Invalid/incomplete authored data rejects before offers. Older assertions that restricted the outer pair to rank four were updated in offer, balance and lightning fixtures.

The first native test counted five hidden shots left by its preceding pooling scenario as part of P2's new volley. Explicitly recycling those fixture shots before the presentation section resolved all eight count failures; the complete native suite was rerun cleanly. This required no gameplay workaround.

Twenty-one native captures cover all four ranks in solo/co-op/wide layouts and rank-two/three/four cards. Inspected `side_coop_rank_2.webp`, `side_coop_rank_3.webp`, `side_coop_rank_4.webp`, `side_wide_rank_2.webp`, `side_coop_offer_2.webp` and `side_coop_offer_3.webp`: the smaller shots keep the existing team palette and pixel treatment; descriptions fit both personal cards. Captures and `earlier_sides_native.log` / `earlier_sides_native_errors.log` remain in the ignored validation project.

Changed-scope visual review (0 = fail, 1 = partial, 2 = clear): `TYPE-GLYPH-INTEGRITY` 2 (readable card text), `TYPE-STAT-ALIGN` 2 (paired damage rows), `SPACE-PLAYFIELD` 2 (shots remain ordinary combat effects), `ICON-PIXEL-LOCK` 2 (existing native projectile frames) and `COLOR-ONLY` 2 (outer size and trajectories supplement team color). No changed-scope zeroes. Final usefulness/balance awaits maintainer playtest.

Previous gameplay work and local MCP activation edits were preserved. No additional upgrade family, slot or roadmap phase was added.

## Rank-three visual follow-up — 2026-10-28

The maintainer requested a small graphical improvement at rank three. The existing native inner-projectile frame now has brighter shoulder highlights, two lateral glints and a short colored tail. Both team rows retain Lost Warden 64 colors. The editable `pulse_shot_side_master.ase` source stores these sixteen changed pixels in a separate `Rank 3 accents` layer, present only in frame three (atlas column two). The other eight team/tier cells remain pixel-identical; the final source re-export matches the runtime PNG exactly. No gameplay script, authored damage, collider, trajectory or timing changed in this follow-up. The existing medium outer pair remains.

The editor's single-file refresh initially left the compiled texture stale. An addon-free headless editor import refreshed it; a separate pixel audit compares every opaque runtime texture pixel and alpha against the final PNG. The existing 278-check native suite is rerun after that import, with solo/co-op/wide captures inspected. Changed-scope visual scores: `ICON-PIXEL-LOCK` 2 (native pixel accents), `COLOR-ROLES` 2 (red/blue energy ramps), `COLOR-ONLY` 2 (lateral glints and tail also change the silhouette). Import, texture audit and native logs remain in the ignored validation project.
