# Defensive role separation validation — 2026-10-26

Implemented the [approved role split](plan.md), including the maintainer's subsequent request for asteroid activation. Reflection reflects physical hostile shots one charge at a time. Enemy and asteroid hull contacts break the whole sphere without absorbing their damage; continuous beams bypass it without consuming charges. A ready Retaliation Pulse can protect against the same enemy or asteroid contact that breaks Reflection. Ranged attacks cannot trigger retaliation.

The obsolete reflector body-cooldown cache and authored cadence were removed. Body detection uses the actual player hull rather than the projectile interception circle. Existing physics-confirmed contact forwarding remains in place.

## Runtime verification

Godot 4.7.2; addon-free `.godot/phase_2_runtime_validation/` project with source junctions and isolated APPDATA directories. Native runs use OpenGL Compatibility and the RTX 3060.

The following table records the initial role-split checkpoint. See the asteroid activation follow-up below for the latest contact rules and test counts.

| Suite | Checks | Result |
| --- | ---: | --- |
| Shield body rupture, headless and native | 142 each | Pass |
| Defensive pack, headless | 256 | Pass |
| Defensive pack, native | 343 | Pass |
| Hull contacts, headless | 74 | Pass |
| Shield throwback, headless | 79 | Pass |
| Player hit contract, headless | 41 | Pass |
| Guard blades, headless | 234 | Pass |
| Upgrade offers, headless | 4,531 | Pass |
| Upgrade selection, headless | 65 | Assertions pass; shutdown note below |

The new rupture suite fails against the former body-absorption contract, then passes against the approved separation. It tests small asteroids, large asteroids and enemy hulls at all three reflector ranks; complete sphere rupture and recharge; hull injury and repeated contact; callback/query injury deduplication; reflection-plus-retaliation combinations; unchanged projectile ownership, charge counts, reversal and pooling; and beam bypass. Both final native combat stderr logs are empty.

The selection suite reports two MP3 playback objects and one music resource still held at process shutdown. A verbose rerun identifies `Retro-Futurist Drive.mp3`, not the defensive assets. Its 65 behavior assertions pass. No audio code or unrelated test teardown was changed; this shutdown warning remains outside this delivery.

## Icons and presentation, revised after maintainer feedback

The maintainer rejected the generated mirror/starburst icons and pointed vector burst and requested the golden explosion. [Rejected prompts and replacement source references](../../../../assets/sources/ui/defense_roles_prompts.md) document this change. The rejected standalone PNGs and their import sidecars were removed.

Both icons now use native ship artwork. Reflection shows a cyan field and a projectile ricochet; Retaliation shows the ship inside the existing golden pixel-art explosion, with detached impact sparks. The 16px HUD versions use the original miniature ship rather than downsampling the large generated images. Editable Aseprite sources contain a separate `Projectile reflection and golden retaliation` layer.

Only shield column 6 and retaliation column 18 were replaced, in both owner rows. All **36 other cells per atlas remain byte-identical**, for 72 preserved cells across the menu and HUD atlases. Exporting both source atlases reproduces the runtime PNG pixel data exactly. Godot imports were refreshed.

Reflection retains the icy-cyan sphere, reflection arrows and rupture fragments. Retaliation retains the small amber ready diamond and protection sparks, but its blast now reuses `assets/sprites/combat/impact_explosion.png`. The mature golden front scales continuously with the active damage radius (64/80/96px), holds until 0.35s, then uses the native cooling-fragment frames until 0.60s. Both players use gold for retaliation, including target hit feedback. No gameplay timings or contact rules changed in this visual revision.

After the revision, the defensive suite again passes **256 headless and 343 native assertions**. Native captures cover solo/co-op/wide layouts, both owners, expansion, recharge and the selection cards. Inspected the final `defense_coop_wave_4.webp`, `defense_coop_blue_3.webp` and `defense_coop_choices.webp`: the gold burst is visible for both owners, the cyan reflector remains readable, and native icons and two-line summaries fit the cards. Four-wave visual limits, damage radius, active hold, cancellation and projectile clearing remain covered by the suite. A focused native presentation rerun passes another 87 assertions. Its verbose shutdown log confirms that the two retained objects are `AudioStreamMP3` and `AudioStreamPlaybackMP3`, holding `Retro-Futurist Drive.mp3`: the previously observed selection-audio warning, unrelated to defensive art. Logs: `defense_gold_native.log`, `defense_gold_native_errors.log`, `defense_gold_visual_verbose.log` and `defense_gold_visual_verbose_errors.log` in the ignored validation project.

`git diff --check` passes. Existing local MCP activation changes in `project.godot` remain untouched. No commit or publication requested. Await maintainer playtest; these checks do not establish final gameplay balance.

## Asteroid activation follow-up

The maintainer subsequently requested that asteroids also trigger Retaliation Pulse. Validated enemy and asteroid body contacts now share the existing trigger path; the explicit small/large asteroid exclusion was removed. A ready charge cancels the contact hit and starts the same golden counterattack, 0.6s protection and rank-specific recharge. Reflection still shatters first on body impact. Projectiles and beams remain unable to trigger retaliation. The resource description explicitly includes enemies and asteroids; the selection summary now says `BODY CONTACT`.

Updated regressions fail against the old asteroid exclusion and pass with the new behavior. Small and large asteroid query contacts are covered at all three retaliation ranks. Callback tests cover both enemy and asteroid layers and preserve player collision-mask filtering. Combined reflection/retaliation tests cover all ranks, duplicate callbacks, a single wave and ordinary injury during recharge after protection expires.

| Latest suite | Checks | Result |
| --- | ---: | --- |
| Shield body rupture, headless | 199 | Pass |
| Defensive pack, headless | 270 | Pass |
| Hull contacts, headless | 90 | Pass |
| Defensive pack, native | 357 | Pass; stderr empty |

The native run includes the asteroid regressions, projectile/beam exclusions and solo/co-op/wide presentation captures. Inspected the updated co-op selection capture to confirm the new contact label fits. Golden artwork and balance values are unchanged. Native logs: `pulse_asteroids_native.log` and `pulse_asteroids_native_errors.log` in the ignored validation project. `git diff --check` passes.

## Compact rank-one and native-size explosion follow-up

The maintainer found rank one's explosion too large and the effect visibly magnified. Rank one's radius is now **48px instead of 64px** (25% smaller); ranks two/three remain 80/96px. The previous shared impact sheet was enlarged by up to 2.67 times. Retaliation now uses its dedicated editable `assets/sources/player/weapons/retaliation_pulse.aseprite` at the actual 48/80/96px radii, with fine golden contours and restrained cooling fragments. There are three rank rows, eight frames and 224px square cells. Both players share the golden effect. Runtime expansion selects the next native-size front and only scales downward to match the continuous damage radius; active hold and cooling use the native mature size. No frame is enlarged.

Damage, recharge, protection, body/asteroid triggers, projectile/beam exclusions, owner attribution and 0.20/0.35/0.60s boundaries are unchanged. The existing card and HUD values still read the resource. No icon changes were needed.

| Latest verification | Checks | Result |
| --- | ---: | --- |
| Defensive pack, headless | 274 | Pass |
| Defensive pack, native | 361 | Pass; stderr empty |
| Focused native presentation, both owners/all ranks | 63 | Pass; stderr empty |

The rank-one regression keeps a hull and shot at 60px untouched while still accepting later arrivals inside 48px during the active hold. All ranks retain edge/outside damage coverage, and the suite verifies that expansion never magnifies the artwork. The focused preview uses actual asteroid overlaps and captures 0/40/100/200/400ms phases for both players. Its initial fixture incorrectly assumed 12 starting energy; it was corrected to set that value explicitly, without a runtime change.

Inspected the final rank-one mature front, rank-two expansion and rank-one cooling captures: gold remains legible, the ship stays visible, the contour is fine rather than enlarged, and inactive fragments are distinct. These captures and `pulse_compact_{native,visual}*.log` are in the ignored validation project. Exporting all eight Aseprite frames reproduces the runtime PNG RGBA exactly; JSON frame bounds and atlas dimensions match. Godot imports were refreshed. `git diff --check` passes. No commit requested.

## Original Reflection colors and icons restored

The maintainer requested the original Reflection appearance again: red for the red player and blue for the blue player, with the former icon. The universal cyan shader was removed; the original sphere sheet supplies both team colors, and reflection/rupture accents now use matching owner colors. Column 6 in both 64px menu and 16px HUD atlases exactly matches the original red/blue cells from HEAD. Editable Aseprite layers retain the restored artwork. The other 38 cells per atlas, including golden Retaliation, are unchanged from the preceding revision; both source exports reproduce runtime RGBA exactly.

Shield throwback passes 79 headless checks. Focused native defensive presentation passes 87 checks with empty stderr and includes solo/co-op/wide capture states. After refreshing a stale icon import, inspected the final red/blue spheres, restored menu icon rows and HUD miniatures. Validation's imported-resource directory is a junction to the main editor cache; copying compiled textures onto it was unnecessary. No reflection/contact behavior or balance changed. Logs: `team_shield_visual.log`, `team_shield_visual_errors.log` and `team_shield_import.log` in the ignored validation project.

## Reactive Armor explanation — 2026-10-28

The maintainer found this upgrade unclear. Its behavior was verified against the vitals and defense code: a nonfatal hull injury costs energy, then ordinary projectile/body hits are ignored for 1.25/1.50/1.75s instead of the base 1s. Continuous beams retain their own damage cadence. Reflection interception or Retaliation cancelling a contact does not count as hull damage.

The card's ambiguous percentage protection text was replaced by `AFTER HULL DAMAGE` and `1.25/1.50/1.75S IMMUNITY / NO BEAMS`. The full resource description explains the activating injury, subsequent shot/contact protection, baseline and beam exception. No combat values, mechanics, icon or effects changed.

The existing defensive suite passes 274 headless checks, including every armor rank's real HP loss, grace duration, blocked subsequent hits, beam bypass and resumption after expiration. Focused native presentation passes 87 checks with empty stderr. Inspected co-op and solo cards; the trigger, duration and beam exception fit the existing two-line area. Logs: `armor_copy_native.log` and `armor_copy_native_errors.log` in the ignored validation project. `git diff --check` passes.
