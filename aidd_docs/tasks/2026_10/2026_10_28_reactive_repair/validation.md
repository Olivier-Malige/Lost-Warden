# Reactive Armor delayed repair — 2026-10-28

The maintainer found extra injury invulnerability unclear and less useful than other utilities, then approved a repair role. Implemented locally as a scoped Phase 3 revision. No commit or publication requested.

## Current contract

| Rank | Recovery | Time without new hull damage |
| --- | ---: | ---: |
| 1 | 1 hull point | 8 seconds |
| 2 | 1 hull point | 6 seconds |
| 3 | 1 hull point | 4 seconds |

An accepted nonfatal hull injury starts one pending repair. Any further accepted injury restarts the full delay, including continuous beam ticks. Completing the delay restores exactly one point, capped at hull capacity, and consumes the pending recovery. Injuries do not stack and cannot become continuous regeneration. Acquiring the utility does not repair an earlier wound. Ordinary one-second injury grace, slowdown and hit flash remain; the former extra grace bonus is removed.

Reflection absorption and Retaliation protection do not start or reset repair because neither loses hull energy. Rank upgrades preserve elapsed progress as a fraction of the new delay without healing immediately. Pause freezes repair, filling hull with a health reward cancels it, and death clears it without resurrection. Each co-op owner has independent state.

`reactive_armor.tres` authors all repair amounts and delays, with resource validation before offers. PlayerDefenses owns the countdown and publishes it through the existing Events defense snapshot; PlayerVitals alone restores hull energy. The existing HUD creates a green personal countdown/progress bar and briefly shows `REPAIRED +1` on completion. It works with or without Reflection. Cards state the hull-hit trigger, one-point recovery and quiet delay. Existing armor art and utility slots are retained.

## Verification

Godot 4.7.2, addon-free `.godot/phase_2_runtime_validation/` project, isolated APPDATA. Native rendering uses OpenGL Compatibility on the RTX 3060.

| Suite | Checks | Result |
| --- | ---: | --- |
| Reactive repair, headless | 74 | Pass |
| Reactive repair, native | 122 | Pass; stderr empty |
| Defensive pack | 274 | Pass |
| Hull contacts | 90 | Pass |
| Reflection body rupture | 199 | Pass |
| Player hit contract | 41 | Pass |
| Upgrade offers | 4,531 | Pass |
| Upgrade selection | 76 | Pass; clean exit on this run |

Coverage includes malformed resource rejection, all rank timing boundaries, new injury and beam resets, one-point-only recovery, shield/Pulse interaction, pause/rank progress preservation, capacity and health rewards, lethal damage, co-op independence, actual native projectiles, HUD events and hull pip restoration. Existing defensive/contact fixtures now assert ordinary one-second grace and the pending repair rather than the removed armor grace bonus.

Native screenshots cover solo, co-op and wide windows: start, halfway, reset by injury, coexistence with Reflection, completion and selection descriptions. Inspected `repair_solo_half.webp`, `repair_coop_with_shield.webp`, `repair_coop_complete.webp`, `repair_coop_choices.webp`, `repair_wide_with_shield.webp` and `repair_wide_choices.webp`. The bar stays in the HUD columns, shield and repair labels have separate rows, and both players' cards remain legible. Native logs and all eighteen captures remain in the ignored validation project.

Changed-scope visual review (0 = fail, 1 = partial, 2 = clear):

| Receptor | Score | Observed evidence |
| --- | ---: | --- |
| TYPE-GLYPH-INTEGRITY | 2 | Native pixel labels and countdown digits remain readable. |
| TYPE-TIMER-STABLE | 2 | Countdown uses fixed decimal precision and a stable bar width. |
| HIER-PERIPH-READ | 2 | Progress is visible as a filled bar alongside its countdown. |
| SPACE-PLAYFIELD | 2 | Repair stays within the existing side columns. |
| SPACE-PROX-CLUSTER | 2 | Personal repair status sits beside the owner's defense state. |
| COLOR-ONLY | 2 | Text and bar progress duplicate the green recovery cue. |

No new raster assets, runtime nodes per injury, autoloads or direct HUD/player coupling were introduced. Previous gameplay changes and local MCP activation edits were preserved. This verifies behavior and presentation; final gameplay usefulness and tuning await maintainer playtest.
